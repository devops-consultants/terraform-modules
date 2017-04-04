require 'rest-client'
require 'xmlsimple'

# Read Command line parameters
vm_name = ARGV[0]
num_bricks = ARGV[1].to_i
brick_size = ARGV[2]

# Authenticate with the vCloud API
begin
    vcloud_session = RestClient::Resource.new('${vcd_api_url}/sessions',
                                              "#{ENV['VCLOUD_USERNAME']}@#{ENV['VCLOUD_ORG']}",
                                              ENV['VCLOUD_PASSWORD'])
    auth = vcloud_session.post '', :accept => 'application/*+xml;version=5.6'
    auth_token = auth.headers[:x_vcloud_authorization]
rescue => e
        puts e.response
end

# Use the Query API to search for the 'vm_name' VM in order to extract the HREF and append
# to the HREF url '/virtualHardwareSection/disks' to examine what disks are currently provisioned.
begin
    response = RestClient.get "${vcd_api_url}/query?type=vm&filter=(name==#{vm_name})",
                                {'x-vcloud-authorization' => auth_token,
                                 :accept => 'application/*+xml;version=5.6'}
rescue => e
    puts e.response
end

parsed = XmlSimple.xml_in(response.to_str)

disk_url = ''
parsed['VMRecord'].each do |vm|
    disk_url = "#{vm['href']}/virtualHardwareSection/disks"
end

# Query what disks are currently provisioned for the VM
begin
    response = RestClient.get disk_url,
                            {'x-vcloud-authorization' => auth_token,
                             :accept => 'application/*+xml;version=5.6'}
rescue => e
    puts e.response
end

hardware_xml = response.to_str
hardware = XmlSimple.xml_in(hardware_xml)

found_bricks = 0
storageProfileHref = ""
lastInstanceId = 0

# Ignoring the disk controllers and the first 'OS' disk, count any additional disks
# already provisioned. Keep track of the storage profile and the instanceId for use
# later when defining a new disk to provision.
hardware['Item'].each do |disk|
    if disk['Description'][0] == "Hard disk" 
        storageProfileHref = disk['HostResource'][0]['vcloud:storageProfileHref']
        lastInstanceId = disk['InstanceID'][0].to_i
        if disk['AddressOnParent'][0].to_i > 0 
            found_bricks = found_bricks + 1
        end
    end
end

# If not enough additional disks have been provisioned, append a new chunk of XML
# to the RasdItemsList ready to 'PUT' it back to the vCloud API.
if num_bricks - found_bricks > 0
    $stdout.sync = true
    print "Creating #{num_bricks - found_bricks} additional disks: "

    (found_bricks + 1).upto(num_bricks) do |disk_num|
        lastInstanceId = lastInstanceId + 1

        new_disk_xml = "    <Item>
        <rasd:AddressOnParent>#{disk_num}</rasd:AddressOnParent>
        <rasd:Description>Hard disk</rasd:Description>
        <rasd:ElementName>Hard disk #{disk_num + 1}</rasd:ElementName>
        <rasd:HostResource xmlns:vcloud=\"http://www.vmware.com/vcloud/v1.5\" vcloud:capacity=\"#{brick_size}\" vcloud:storageProfileOverrideVmDefault=\"false\" vcloud:busSubType=\"VirtualSCSI\" vcloud:storageProfileHref=\"#{storageProfileHref}\" vcloud:busType=\"6\"></rasd:HostResource>
        <rasd:InstanceID>#{lastInstanceId}</rasd:InstanceID>
        <rasd:Parent>2</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
    </Item>
</RasdItemsList>"

        hardware_xml = hardware_xml.gsub('</RasdItemsList>', new_disk_xml)
    end

    # 'PUT' the RasdItemsList XML to trigger an asynchronous task to update the VM
    begin
        response = RestClient::Request.execute(method: :put, url: disk_url,
                                payload: hardware_xml, 
                                headers: {'x-vcloud-authorization' => auth_token,
                                          :accept => 'application/*+xml;version=5.6',
                                          'Content-Type' => 'application/vnd.vmware.vcloud.rasdItemsList+xml'})

    rescue => e
        puts e.response
    end

    # The response from the 'PUT' is the task details. 
    task = XmlSimple.xml_in(response.to_str)

    task_url = task['href']
    task_status = task['status']

    # Loop querying the task status, waiting for the task to complete
    while task_status == 'running' do
        begin
        response = RestClient.get task_url,
                                {'x-vcloud-authorization' => auth_token,
                                 :accept => 'application/*+xml;version=5.6'}
        rescue => e
            puts e.response
        end

        task = XmlSimple.xml_in(response.to_str)
        task_status = task['status']

        # Sleep for 2 seconds and check the task status again.
        if task_status == 'running'
            print '.'
            sleep 2
        end
    end

    puts task_status
end
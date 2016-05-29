##Noramal Reference Platfor-NRP to build instance through AWS

require 'cfndsl'
require File.join(File.dirname(__FILE__), '../lib/clientcommon')
require File.join(File.dirname(__FILE__), '../lib/srp')

raise "This template requires the constants 'SrpConfig' and 'AmiData' to be defined." unless [:AmiData, :NrpConfig].all? {|c| const_defined?(c) }

nrp_config = NrpConfig
heat_mode = const_defined?(:OrchestrationEnvironment) && OrchestrationEnvironment == "heat"
region = heat_mode ? "nova" : {"Ref" => "AWS::Region"}

nrp = NRP.new( NrpConfig )
cluster = nrp.clusters['generic']
description = cluster.config['description'] || "generic cluster"

ClientCommon::client_boilerplate(description, heat_mode, AmiData) {
  cluster.facets.values.each do |facet|
    config = facet.config
    size = facet.config["count"] || 1

    size.times do |i|
      machine_name = facet.generic_clusters + "#{i}" 
      volumes = ClientCommon::volume_defaults(config["volumes"], heat_mode, config["ephemerals"] )

      public_ip = facet.config.key?('public_ip') ? facet.config["public_ip"] : false

      firewall_group = ClientCommon::create_security_groups(self, facet.name, config['firewall']) if config.key?('firewall')

      extra_dependencies = nil
      instance_type = config["instance_type"]
      placement_group = config["placement_group"]
      userdata = ClientCommon::userdata(volumes, heat_mode, facet_name: facet.name, facet: facet, facet_index: i)
      security_groups = [ Ref(:NrpSecurityGroup) ]
      security_groups.push Ref(firewall_group) if firewall_group
      boot_snapshot_id = nrp_config['boot_snapshot_id'] && nrp_config['boot_snapshot_id']['client']
      ebs_optimized = true if config.key?("ebs_optimized") && config["ebs_optimized"]
      ClientCommon::create_instance_and_volumes(
        boot_snapshot_id: boot_snapshot_id,
        ebs_optimized: ebs_optimized,
        extra_dependencies: extra_dependencies,
        heat_mode: heat_mode,
        instance_type: instance_type,
        machine_name: machine_name,
        placement_group: placement_group,
        public_ip: public_ip,
        region: region,
        security_groups: security_groups,
        template: self,
        userdata: userdata,
        volumes: volumes,
      )
    end
  end
}

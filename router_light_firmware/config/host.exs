import Config

# Add configuration that is only needed when running on the host here.

config :snmp, :manager, config: [dir: './rootfs_overlay/snmp', db_dir: '/tmp']

require 'docker'
require_relative '../logging'
require_relative '../helpers/weave_helper'

module Kontena::Workers
  class WeaveWorker
    include Celluloid
    include Celluloid::Notifications
    include Kontena::Logging
    include Kontena::Helpers::WeaveHelper

    def initialize
      info 'initialized'
      subscribe('network_adapter:start', :on_weave_start)
      subscribe('container:event', :on_container_event)
      subscribe('dns:add', :on_dns_add)
    end

    def on_weave_start(topic, data)
      self.start
    end

    def start
      wait_running! { debug "start: waiting for weave to be running..." }
      info 'attaching network to existing containers'
      Docker::Container.all(all: false).each do |container|
        self.weave_attach(container)
      end
    end

    def on_dns_add(topic, event)
      wait_running! { debug "on_dns_add: waiting for weave to be running..." }
      add_dns(event[:id], event[:ip], event[:name])
    end

    # @param [String] topic
    # @param [Docker::Event] event
    def on_container_event(topic, event)
      if event.status == 'start'
        container = Docker::Container.get(event.id) rescue nil
        if container
          self.weave_attach(container)
        end
      elsif event.status == 'destroy'
        self.weave_detach(event)
      elsif event.status == 'restart'
        if router_image?(event.from)
          self.start
        end
      end
    end

    # @param [Docker::Container] container
    def weave_attach(container)
      wait_running! { debug "weave_attach: waiting for weave to be running..." }

      config = container.info['Config'] || container.json['Config']
      labels = config['Labels'] || {}
      overlay_cidr = labels['io.kontena.container.overlay_cidr']
      if overlay_cidr
        container_name = labels['io.kontena.container.name']
        service_name = labels['io.kontena.service.name']
        grid_name = labels['io.kontena.grid.name']
        ip = overlay_cidr.split('/')[0]

        Actor[:network_adapter].attach_container(container, overlay_cidr)

        # register DNS names once attached
        dns_names = [
          "#{container_name}.kontena.local",
          "#{service_name}.kontena.local",
          "#{container_name}.#{grid_name}.kontena.local",
          "#{service_name}.#{grid_name}.kontena.local"
        ]
        dns_names.each do |name|
          add_dns(container.id, ip, name)
        end
      end
    rescue Docker::Error::NotFoundError => error
      warn "ignoring weave attach for missing container: #{error}"
    rescue => error
      error_exception error, "weave attach for container #{container.name}: #{error}"
    end

    # @param [Docker::Event] event
    def weave_detach(event)
      wait_running! { debug "weave_detach: waiting for weave to be running..." }

      remove_dns(event.id)
    rescue Docker::Error::NotFoundError => error
      warn "ignoring weave detach for missing container: #{error}"
    rescue => error
      error_exception error, "weave detach for container #{event.id}: #{error}"
    end
  end
end

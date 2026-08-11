defmodule SmaLix.Sources.SHM2.Sensors do
  @moduledoc """
  Home Assistant MQTT-autodiscovery sensor definitions for the SHM2 source.
  Transcribed from `SENSORS_SHM2` in `plugins/sources/SHM2/shm2.py`.
  """

  @sensors [
    # device info
    %{key: "device_info.name", enabled: true, name: "Device name", entity_category: "diagnostic"},
    %{
      key: "device_info.identifiers",
      enabled: true,
      name: "Device serial",
      entity_category: "diagnostic"
    },
    %{
      key: "device_info.model",
      enabled: true,
      name: "Device model",
      entity_category: "diagnostic"
    },
    %{
      key: "device_info.manufacturer",
      enabled: true,
      name: "Device manufacturer",
      entity_category: "diagnostic"
    },
    %{
      key: "device_info.sw_version",
      enabled: true,
      name: "Device SW version",
      entity_category: "diagnostic"
    },
    # global measurements
    %{
      key: "p.pconsume",
      enabled: true,
      name: "Active power consumption",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.pconsumecounter",
      enabled: true,
      name: "Active power consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "p.psupply",
      enabled: true,
      name: "Active power supply",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.psupplycounter",
      enabled: true,
      name: "Active power supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.qconsume",
      enabled: true,
      name: "Reactive power consumption",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.qconsumecounter",
      enabled: true,
      name: "Reactive power consumption counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.qsupply",
      enabled: true,
      name: "Reactive power supply",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.qsupplycounter",
      enabled: true,
      name: "Reactive power supply counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.sconsume",
      enabled: true,
      name: "Apparent power consumption",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.sconsumecounter",
      enabled: true,
      name: "Apparent power consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.ssupply",
      enabled: true,
      name: "Apparent power supply",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.ssupplycounter",
      enabled: true,
      name: "Apparent power supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "cosphi",
      enabled: true,
      name: "Phase angle cosine",
      unit_of_measurement: "°",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:cosine-wave"
    },
    %{
      key: "frequency",
      enabled: true,
      name: "Grid frequency",
      device_class: "frequency",
      unit_of_measurement: "Hz",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:sine-wave"
    },
    # phase 1
    %{
      key: "p.1.p1consume",
      enabled: false,
      name: "Phase 1 consumption",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.1.p1consumecounter",
      enabled: false,
      name: "Phase 1 consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "p.1.p1supply",
      enabled: false,
      name: "Phase 1 active power supply",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.1.p1supplycounter",
      enabled: false,
      name: "Phase 1 supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.1.q1consume",
      enabled: false,
      name: "Phase 1 reactive power consumption",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.1.q1consumecounter",
      enabled: false,
      name: "Phase 1 reactive power consumption counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.1.q1supply",
      enabled: false,
      name: "Phase 1 reactive power supply",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.1.q1supplycounter",
      enabled: false,
      name: "Phase 1 reactive power supply counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.1.s1consume",
      enabled: false,
      name: "Phase 1 apparent power consumption",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.1.s1consumecounter",
      enabled: false,
      name: "Phase 1 apparent power consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.1.s1supply",
      enabled: false,
      name: "Phase 1 apparent power supply",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.1.s1supplycounter",
      enabled: false,
      name: "Phase 1 apparent power supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "1.i1",
      enabled: false,
      name: "Phase 1 current",
      device_class: "current",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:current-ac"
    },
    %{
      key: "1.u1",
      enabled: false,
      name: "Phase 1 potential",
      device_class: "voltage",
      unit_of_measurement: "V",
      icon: "mdi:flash-triangle-outline",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "1.cosphi1",
      enabled: false,
      name: "Phase 1 angle cosine",
      unit_of_measurement: "°",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:cosine-wave"
    },
    # phase 2
    %{
      key: "p.2.p2consume",
      enabled: false,
      name: "Phase 2 consumption",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.2.p2consumecounter",
      enabled: false,
      name: "Phase 2 consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "p.2.p2supply",
      enabled: false,
      name: "Phase 2 active power supply",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.2.p2supplycounter",
      enabled: false,
      name: "Phase 2 supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.2.q2consume",
      enabled: false,
      name: "Phase 2 reactive power consumption",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.2.q2consumecounter",
      enabled: false,
      name: "Phase 2 reactive power consumption counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.2.q2supply",
      enabled: false,
      name: "Phase 2 reactive power supply",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.2.q2supplycounter",
      enabled: false,
      name: "Phase 2 reactive power supply counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.2.s2consume",
      enabled: false,
      name: "Phase 2 apparent power consumption",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.2.s2consumecounter",
      enabled: false,
      name: "Phase 2 apparent power consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.2.s2supply",
      enabled: false,
      name: "Phase 2 apparent power supply",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.2.s2supplycounter",
      enabled: false,
      name: "Phase 2 apparent power supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "2.i2",
      enabled: false,
      name: "Phase 2 current",
      device_class: "current",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:current-ac"
    },
    %{
      key: "2.u2",
      enabled: false,
      name: "Phase 2 potential",
      device_class: "voltage",
      unit_of_measurement: "V",
      icon: "mdi:flash-triangle-outline",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "2.cosphi2",
      enabled: false,
      name: "Phase 2 angle cosine",
      unit_of_measurement: "°",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:cosine-wave"
    },
    # phase 3
    %{
      key: "p.3.p3consume",
      enabled: false,
      name: "Phase 3 consumption",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.3.p3consumecounter",
      enabled: false,
      name: "Phase 3 consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "p.3.p3supply",
      enabled: false,
      name: "Phase 3 active power supply",
      device_class: "power",
      unit_of_measurement: "W",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "p.3.p3supplycounter",
      enabled: false,
      name: "Phase 3 supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.3.q3consume",
      enabled: false,
      name: "Phase 3 reactive power consumption",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.3.q3consumecounter",
      enabled: false,
      name: "Phase 3 reactive power consumption counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "q.3.q3supply",
      enabled: false,
      name: "Phase 3 reactive power supply",
      device_class: "reactive_power",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "q.3.q3supplycounter",
      enabled: false,
      name: "Phase 3 reactive power supply counter",
      device_class: "reactive_energy",
      unit_of_measurement: "kvarh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.3.s3consume",
      enabled: false,
      name: "Phase 3 apparent power consumption",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.3.s3consumecounter",
      enabled: false,
      name: "Phase 3 apparent power consumption counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "s.3.s3supply",
      enabled: false,
      name: "Phase 3 apparent power supply",
      device_class: "apparent_power",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:home-lightning-bolt-outline"
    },
    %{
      key: "s.3.s3supplycounter",
      enabled: false,
      name: "Phase 3 apparent power supply counter",
      device_class: "energy",
      unit_of_measurement: "kWh",
      state_class: "total_increasing",
      suggested_display_precision: 2,
      icon: "mdi:counter"
    },
    %{
      key: "3.i3",
      enabled: false,
      name: "Phase 3 current",
      device_class: "current",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:current-ac"
    },
    %{
      key: "3.u3",
      enabled: false,
      name: "Phase 3 potential",
      device_class: "voltage",
      unit_of_measurement: "V",
      icon: "mdi:flash-triangle-outline",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "3.cosphi3",
      enabled: false,
      name: "Phase 3 angle cosine",
      unit_of_measurement: "°",
      state_class: "measurement",
      suggested_display_precision: 2,
      icon: "mdi:cosine-wave"
    }
  ]

  @doc "The list of SHM2 sensor definitions."
  @spec list() :: [map()]
  def list, do: @sensors
end

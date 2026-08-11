defmodule SmaLix.Sources.EvCharger.Sensors do
  @moduledoc """
  Home Assistant sensor definitions for the EV Charger source.
  Transcribed from `SENSORS_EVCHARGER` in `plugins/sources/EVCharger/evcharger.py`.
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
    # configuration and status data
    %{
      key: "ChaSess.WhIn",
      enabled: true,
      name: "Charging session consumption",
      device_class: "energy",
      icon: "mdi:counter",
      unit_of_measurement: "Wh",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{key: "Chrg.ModSw", enabled: true, name: "Charge mode switch"},
    %{
      key: "GridMs.A.phsA",
      enabled: true,
      name: "Phase 1 grid current",
      device_class: "current",
      icon: "mdi:current-ac",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.A.phsB",
      enabled: true,
      name: "Phase 2 grid current",
      device_class: "current",
      icon: "mdi:current-ac",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.A.phsC",
      enabled: true,
      name: "Phase 3 grid current",
      device_class: "current",
      icon: "mdi:current-ac",
      unit_of_measurement: "A",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.Hz",
      enabled: true,
      name: "Grid frequency",
      device_class: "frequency",
      icon: "mdi:sine-wave",
      unit_of_measurement: "Hz",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.PhV.phsA",
      enabled: true,
      name: "Phase 1 grid voltage",
      device_class: "voltage",
      icon: "mdi:flash-triangle-outline",
      unit_of_measurement: "V",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.PhV.phsB",
      enabled: true,
      name: "Phase 2 grid voltage",
      device_class: "voltage",
      icon: "mdi:flash-triangle-outline",
      unit_of_measurement: "V",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.PhV.phsC",
      enabled: true,
      name: "Phase 3 grid voltage",
      device_class: "voltage",
      icon: "mdi:flash-triangle-outline",
      unit_of_measurement: "V",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{key: "GridMs.TotPF", enabled: true, name: "Grid displacement factor"},
    %{
      key: "GridMs.TotVA",
      enabled: true,
      name: "Apparent power",
      device_class: "apparent_power",
      icon: "mdi:home-lightning-bolt-outline",
      unit_of_measurement: "VA",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{
      key: "GridMs.TotVAr",
      enabled: true,
      name: "Reactive power",
      device_class: "reactive_power",
      icon: "mdi:home-lightning-bolt-outline",
      unit_of_measurement: "var",
      state_class: "measurement",
      suggested_display_precision: 2
    },
    %{key: "InOut.GI1", enabled: true, name: "Digital group input"},
    %{
      key: "Metering.GridMs.TotWIn",
      enabled: true,
      name: "Power",
      device_class: "power",
      icon: "mdi:home-lightning-bolt-outline",
      unit_of_measurement: "W"
    },
    %{
      key: "Metering.GridMs.TotWIn.ChaSta",
      enabled: true,
      name: "Power (chargepoint)",
      device_class: "power",
      icon: "mdi:home-lightning-bolt-outline",
      unit_of_measurement: "W"
    },
    %{
      key: "Metering.GridMs.TotWhIn",
      enabled: true,
      name: "Consumption",
      device_class: "energy",
      icon: "mdi:counter",
      unit_of_measurement: "Wh",
      state_class: "total_increasing",
      suggested_display_precision: 2
    },
    %{
      key: "Metering.GridMs.TotWhIn.ChaSta",
      enabled: true,
      name: "Consumption (chargepoint)",
      device_class: "energy",
      icon: "mdi:counter",
      unit_of_measurement: "Wh",
      state_class: "total_increasing",
      suggested_display_precision: 2
    },
    %{key: "Operation.EVeh.ChaStt", enabled: true, name: "Vehicle charging status"},
    %{key: "Operation.EVeh.Health", enabled: true, name: "Vehicle health"},
    %{key: "Operation.Evt.Msg", enabled: true, name: "Status message"},
    %{key: "Operation.Health", enabled: true, name: "Health"},
    %{key: "Operation.WMaxLimNom", enabled: false, name: "Power Limit (Nom)"},
    %{key: "Operation.WMaxLimSrc", enabled: false, name: "Power Limit (Src)"},
    %{key: "Wl.AcqStt", enabled: false, name: "Wifi scan status"},
    %{key: "Wl.ConnStt", enabled: false, name: "Wifi connection status"},
    %{key: "Wl.SigPwr", enabled: false, name: "Wifi signal strength"},
    %{key: "Wl.SoftAcsConnStt", enabled: false, name: "Wifi soft ap status"},
    %{
      key: "Setpoint.PlantControl.PCC.ChrgActCnt",
      enabled: false,
      name: "PlantControl PCC ChrgActCnt"
    }
  ]

  @doc "The list of EV Charger sensor definitions."
  @spec list() :: [map()]
  def list, do: @sensors
end

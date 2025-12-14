from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional, Union

import numpy as np

from .utils import get_logger


LOGGER = get_logger(__name__)


@dataclass(frozen=True)
class BatteryParams:
    capacity_kwh: float = 500.0
    soc_min: float = 0.15
    soc_max: float = 0.95
    charge_max_kw: float = 200.0
    discharge_max_kw: float = 200.0

    @classmethod
    def from_dict(cls, data: Optional[Dict[str, float]]) -> "BatteryParams":
        if not data:
            return cls()
        return cls(
            capacity_kwh=float(data.get("BATTERY_CAP_KWH", cls.capacity_kwh)),
            soc_min=float(data.get("SOC_MIN", cls.soc_min)),
            soc_max=float(data.get("SOC_MAX", cls.soc_max)),
            charge_max_kw=float(data.get("CHARGE_MAX_KW", cls.charge_max_kw)),
            discharge_max_kw=float(
                data.get("DISCHARGE_MAX_KW", cls.discharge_max_kw)
            ),
        )


def optimize_step(
    pred_kwh: float,
    pv_kwh: float,
    soc_kwh: float,
    step_hours: float = 6.0,
    battery_params: Optional[Dict[str, float]] = None,
) -> Dict[str, Union[float, str]]:
    """
    Compute optimal energy dispatch for a microgrid step.

    Args:
        pred_kwh: Forecasted consumption for the next time step.
        pv_kwh: Expected photovoltaic production for the time step.
        soc_kwh: Current battery state-of-charge in kWh.
        step_hours: Duration of the time step in hours.
        battery_params: Optional overrides for battery parameters.

    Returns:
        Dispatch decision dictionary.
    """
    params = BatteryParams.from_dict(battery_params)
    demand = max(pred_kwh, 0.0)
    pv_available = max(pv_kwh, 0.0)
    soc = float(np.clip(soc_kwh, 0.0, params.capacity_kwh))

    pv_used_for_demand = min(demand, pv_available)
    remaining_demand = demand - pv_used_for_demand
    surplus_pv = pv_available - pv_used_for_demand

    battery_charge = 0.0
    battery_discharge = 0.0
    soc_next = soc

    max_charge_kwh = params.charge_max_kw * step_hours
    max_discharge_kwh = params.discharge_max_kw * step_hours

    if surplus_pv > 0:
        available_capacity = max(params.soc_max * params.capacity_kwh - soc_next, 0.0)
        charge_possible = min(surplus_pv, available_capacity, max_charge_kwh)
        battery_charge = max(charge_possible, 0.0)
        soc_next += battery_charge
        note = "PV surplus used to charge battery."
    else:
        available_discharge = max(
            soc_next - params.soc_min * params.capacity_kwh, 0.0
        )
        discharge_required = min(remaining_demand, available_discharge, max_discharge_kwh)
        battery_discharge = max(discharge_required, 0.0)
        soc_next -= battery_discharge
        remaining_demand -= battery_discharge
        note = (
            "Battery discharged to support demand."
            if battery_discharge > 0
            else "Battery preserved due to SOC limits."
        )

    grid_import = max(remaining_demand, 0.0)

    return {
        "grid_import_kWh": float(grid_import),
        "battery_charge_kWh": float(battery_charge),
        "battery_discharge_kWh": float(battery_discharge),
        "soc_next": float(np.clip(soc_next, params.soc_min * params.capacity_kwh, params.capacity_kwh)),
        "note": note,
    }


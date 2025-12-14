package com.microgrid.establishment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SavingsResponse {
    private double annualConsumption;
    private double annualPvEnergy;
    private double annualSavings;
    private double autonomyPercentage;
    private double annualBillAfterPv;
}



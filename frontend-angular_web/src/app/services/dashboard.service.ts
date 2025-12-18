import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface DashboardMetrics {
  currentLoad: number;
  solarGeneration: number;
  systemEfficiency: number;
  batteryStatus: number;
  currentLoadChange: number;
  solarGenerationChange: number;
  efficiencyChange: number;
  batteryStatusChange: number;
}

export interface EnergyFlowData {
  time: string;
  solar: number;
  grid: number;
  battery: number;
  load: number;
}

export interface EfficiencyData {
  hour: string;
  efficiency: number;
}

export interface SavingsResponse {
  annualConsumption: number;
  annualPvProduction: number;
  annualSavings: number;
  autonomy: number;
  annualBillAfterPv: number;
}

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  constructor(private apiService: ApiService) {}

  getSavings(establishmentId: number): Observable<SavingsResponse> {
    return this.apiService.get<SavingsResponse>(`/establishments/${establishmentId}/savings`);
  }

  getComprehensiveResults(establishmentId: number): Observable<any> {
    return this.apiService.get<any>(`/establishments/${establishmentId}/comprehensive-results`);
  }

  // Pour le dashboard, on peut simuler avec les données de l'établissement
  simulateEnergyFlow(establishmentId: number, days: number = 1): Observable<any> {
    const startDate = new Date().toISOString();
    return this.apiService.post<any>(`/establishments/${establishmentId}/simulate`, {
      startDate,
      days,
      batteryCapacityKwh: 500,
      initialSocKwh: 250
    });
  }

  // Calculer les métriques à partir des données de l'établissement
  calculateMetrics(establishment: any, savings: SavingsResponse): DashboardMetrics {
    const monthlyConsumption = establishment.monthlyConsumptionKwh || 0;
    const dailyConsumption = monthlyConsumption / 30;
    const hourlyConsumption = dailyConsumption / 24;
    
    // Estimation basée sur l'autonomie
    const solarGeneration = savings.annualPvProduction / 365 / 24; // kWh par heure
    const currentLoad = hourlyConsumption;
    const systemEfficiency = savings.autonomy || 0;
    const batteryStatus = 78; // Peut être calculé à partir de la simulation
    
    return {
      currentLoad: currentLoad,
      solarGeneration: solarGeneration,
      systemEfficiency: systemEfficiency,
      batteryStatus: batteryStatus,
      currentLoadChange: 2.4,
      solarGenerationChange: 12.5,
      efficiencyChange: 5.2,
      batteryStatusChange: -1.8
    };
  }
}

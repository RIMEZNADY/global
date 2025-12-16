import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface MonthlyData {
  month: string;
  consumption: number;
  generation: number;
  savings: number;
}

export interface DailyData {
  date: string;
  load: number;
  solar: number;
}

@Injectable({
  providedIn: 'root'
})
export class HistoryService {
  constructor(private apiService: ApiService) {}

  getSavings(establishmentId: number): Observable<any> {
    return this.apiService.get<any>(`/establishments/${establishmentId}/savings`);
  }

  getComprehensiveResults(establishmentId: number): Observable<any> {
    return this.apiService.get<any>(`/establishments/${establishmentId}/comprehensive-results`);
  }

  // Simuler des données historiques à partir des données de l'établissement
  getHistoricalData(establishmentId: number): Observable<{ monthly: MonthlyData[], daily: DailyData[] }> {
    return new Observable(observer => {
      this.getSavings(establishmentId).subscribe({
        next: (savings) => {
          // Générer des données mensuelles basées sur les économies
          const monthly: MonthlyData[] = [];
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
          const baseConsumption = savings.annualConsumption / 12;
          const baseGeneration = savings.annualPvProduction / 12;
          
          months.forEach((month, index) => {
            // Variation saisonnière
            const seasonalFactor = 1 + (Math.sin(index * Math.PI / 3) * 0.2);
            monthly.push({
              month,
              consumption: baseConsumption * seasonalFactor,
              generation: baseGeneration * (1.2 + seasonalFactor * 0.3),
              savings: (baseGeneration * (1.2 + seasonalFactor * 0.3) - baseConsumption * seasonalFactor * 0.3)
            });
          });
          
          // Générer des données quotidiennes
          const daily: DailyData[] = [];
          for (let i = 1; i <= 30; i += 5) {
            const dayFactor = 1 + (Math.random() * 0.3 - 0.15);
            daily.push({
              date: i.toString(),
              load: (baseConsumption / 30) * dayFactor,
              solar: (baseGeneration / 30) * dayFactor * 1.5
            });
          }
          
          observer.next({ monthly, daily });
          observer.complete();
        },
        error: (error) => {
          observer.error(error);
        }
      });
    });
  }
}

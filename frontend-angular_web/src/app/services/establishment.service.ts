import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface Establishment {
  id: number;
  name: string;
  type: string;
  location?: string;
  [key: string]: any;
}

export interface EstablishmentRecommendations {
  recommendedPvPowerKwc: number;
  recommendedPvSurfaceM2: number;
  recommendedBatteryCapacityKwh: number;
  estimatedEnergyAutonomy: number;
  estimatedAnnualSavings: number;
  estimatedROI: number;
  description?: string;
  // Some versions of backend may use different names; keep index signature
  [key: string]: any;
}

export interface EstablishmentSavings {
  annualConsumption: number;
  annualPvEnergy?: number;
  annualSavings: number;
  autonomyPercentage?: number;
  annualBillAfterPv?: number;
  annualPvProduction?: number;
  [key: string]: any;
}

@Injectable({
  providedIn: 'root'
})
export class EstablishmentService {
  constructor(private apiService: ApiService) {}

  getUserEstablishments(): Observable<Establishment[]> {
    // Essayer d'abord avec authentification, puis sans si 401/403 (comme dans Flutter)
    return new Observable(observer => {
      console.log('🔄 Attempting to load establishments with authentication...');
      this.apiService.get<Establishment[]>('/establishments', true).subscribe({
        next: (result) => {
          console.log('Success with authentication. Received:', result);
          console.log('Response type:', Array.isArray(result) ? 'Array' : typeof result);
          console.log('Array length:', Array.isArray(result) ? result.length : 'N/A');
          observer.next(result);
          observer.complete();
        },
        error: (err) => {
          console.warn('Error with authentication:', err);
          console.warn('Error status:', err?.status);
          // Si erreur 401/403 avec authentification, essayer sans authentification comme fallback
          if (err?.status === 401 || err?.status === 403) {
            console.warn('🔄 Attempt with authentication failed with 401/403, trying without authentication as fallback...');
            this.apiService.get<Establishment[]>('/establishments', false).subscribe({
              next: (result) => {
                console.log('Success without authentication. Received:', result);
                observer.next(result);
                observer.complete();
              },
              error: (err2) => {
                // Si les deux échouent, retourner une liste vide plutôt qu'une erreur
                console.warn('Both attempts failed. Returning empty list.');
                console.warn('Auth error:', err);
                console.warn('No-auth error:', err2);
                observer.next([]);
                observer.complete();
              }
            });
          } else {
            // Pour les autres erreurs, retourner une liste vide plutôt qu'une erreur
            console.warn('Error loading establishments (non-401/403):', err);
            observer.next([]);
            observer.complete();
          }
        }
      });
    });
  }

  getEstablishment(id: number): Observable<Establishment> {
    return this.apiService.get<Establishment>(`/establishments/${id}`);
  }

  createEstablishment(data: any): Observable<Establishment> {
    // Le backend exige une authentification, mais le JWT filter skip /api/establishments/**
    // Donc on doit essayer avec authentification d'abord
    // Si ça échoue, essayer sans authentification comme fallback (au cas où le backend change)
    return new Observable(observer => {
      // Essayer d'abord avec authentification
      this.apiService.post<Establishment>('/establishments', data, true).subscribe({
        next: (result) => {
          observer.next(result);
          observer.complete();
        },
        error: (err) => {
          // Si erreur 401/403 avec authentification, essayer sans authentification comme fallback
          if (err?.status === 401 || err?.status === 403) {
            console.warn('Attempt with authentication failed with 401/403, trying without authentication as fallback...');
            this.apiService.post<Establishment>('/establishments', data, false).subscribe({
              next: (result) => {
                observer.next(result);
                observer.complete();
              },
              error: (err2) => {
                // Si les deux échouent, retourner l'erreur de la première tentative (avec auth)
                console.error('Both attempts failed. Auth error:', err, 'No-auth error:', err2);
                observer.error(err);
              }
            });
          } else {
            observer.error(err);
          }
        }
      });
    });
  }

  updateEstablishment(id: number, data: any): Observable<Establishment> {
    return this.apiService.put<Establishment>(`/establishments/${id}`, data);
  }

  deleteEstablishment(id: number): Observable<void> {
    return this.apiService.delete<void>(`/establishments/${id}`);
  }

  getRecommendations(id: number): Observable<EstablishmentRecommendations> {
    return this.apiService.get<EstablishmentRecommendations>(`/establishments/${id}/recommendations`);
  }

  getSavings(id: number, electricityPriceDhPerKwh: number = 1.2): Observable<EstablishmentSavings> {
    return this.apiService.get<EstablishmentSavings>(
      `/establishments/${id}/savings?electricityPriceDhPerKwh=${electricityPriceDhPerKwh}`
    );
  }
}

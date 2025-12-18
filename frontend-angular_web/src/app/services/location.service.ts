import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface IrradiationResponse {
  irradiationClass: 'A' | 'B' | 'C' | 'D';
  latitude: number;
  longitude: number;
  nearestCity?: {
    name: string;
    region: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class LocationService {
  private baseUrl = 'http://localhost:8080/api';

  constructor(private http: HttpClient) {}

  getIrradiationClass(latitude: number, longitude: number): Observable<IrradiationResponse> {
    return this.http.get<IrradiationResponse>(
      `${this.baseUrl}/location/irradiation?latitude=${latitude}&longitude=${longitude}`
    );
  }

  getZoneLabel(irradiationClass: string): string {
    const labels: { [key: string]: string } = {
      'A': 'Zone A - Sahara (Très élevée)',
      'B': 'Zone B - Centre (Élevée)',
      'C': 'Zone C - Côtes (Moyenne)',
      'D': 'Zone D - Rif (Faible)'
    };
    return labels[irradiationClass] || irradiationClass;
  }

  // Used by NEW workflow in mobile app: estimate population around a location.
  // Endpoint implemented in backend_common location module (if present).
  estimatePopulation(params: {
    latitude: number;
    longitude: number;
    establishmentType?: string;
    numberOfBeds?: number;
  }): Observable<number> {
    const { latitude, longitude, establishmentType, numberOfBeds } = params;
    const typeParam = establishmentType ? `&establishmentType=${encodeURIComponent(establishmentType)}` : '';
    const bedsParam = numberOfBeds != null ? `&numberOfBeds=${numberOfBeds}` : '';
    return this.http
      .get<{ estimatedPopulation: number }>(
        `${this.baseUrl}/location/estimate-population?latitude=${latitude}&longitude=${longitude}${typeParam}${bedsParam}`
      )
      .pipe(map(res => res.estimatedPopulation));
  }
}


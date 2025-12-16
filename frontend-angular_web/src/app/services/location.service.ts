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
}


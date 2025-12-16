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

@Injectable({
  providedIn: 'root'
})
export class EstablishmentService {
  constructor(private apiService: ApiService) {}

  getUserEstablishments(): Observable<Establishment[]> {
    return this.apiService.get<Establishment[]>('/establishments');
  }

  getEstablishment(id: number): Observable<Establishment> {
    return this.apiService.get<Establishment>(`/establishments/${id}`);
  }

  createEstablishment(data: any): Observable<Establishment> {
    return this.apiService.post<Establishment>('/establishments', data);
  }

  updateEstablishment(id: number, data: any): Observable<Establishment> {
    return this.apiService.put<Establishment>(`/establishments/${id}`, data);
  }

  deleteEstablishment(id: number): Observable<void> {
    return this.apiService.delete<void>(`/establishments/${id}`);
  }
}

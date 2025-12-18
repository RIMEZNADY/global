import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private baseUrl = 'http://localhost:8080/api';
  private tokenKey = 'auth_token';

  constructor(
    private http: HttpClient
  ) {}

  private getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  private getHeaders(includeAuth: boolean = true): HttpHeaders {
    let headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });

    if (includeAuth) {
      const token = this.getToken();
      if (token) {
        // Nettoyer le token (enlever les espaces, retours à la ligne, etc.)
        const cleanToken = token.trim().replace(/\s+/g, '');
        console.log('Setting Authorization header with token:', cleanToken.substring(0, 30) + '...');
        headers = headers.set('Authorization', `Bearer ${cleanToken}`);
      } else {
        console.warn('No token available for Authorization header');
      }
    }

    return headers;
  }

  get<T>(endpoint: string, includeAuth: boolean = true): Observable<T> {
    return this.http.get<T>(`${this.baseUrl}${endpoint}`, {
      headers: this.getHeaders(includeAuth)
    });
  }

  post<T>(endpoint: string, body: any, includeAuth: boolean = true): Observable<T> {
    return this.http.post<T>(`${this.baseUrl}${endpoint}`, body, {
      headers: this.getHeaders(includeAuth)
    });
  }

  put<T>(endpoint: string, body: any, includeAuth: boolean = true): Observable<T> {
    return this.http.put<T>(`${this.baseUrl}${endpoint}`, body, {
      headers: this.getHeaders(includeAuth)
    });
  }

  delete<T>(endpoint: string, includeAuth: boolean = true): Observable<T> {
    return this.http.delete<T>(`${this.baseUrl}${endpoint}`, {
      headers: this.getHeaders(includeAuth)
    });
  }
}

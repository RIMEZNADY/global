import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable } from 'rxjs';
import { ApiService } from './api.service';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface AuthResponse {
  token: string;
  user?: any;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private tokenKey = 'auth_token';
  private isAuthenticatedSubject = new BehaviorSubject<boolean>(this.hasToken());
  public isAuthenticated$ = this.isAuthenticatedSubject.asObservable();

  constructor(
    private apiService: ApiService,
    private router: Router
  ) {}

  login(credentials: LoginRequest): Observable<AuthResponse> {
    return new Observable(observer => {
      this.apiService.post<AuthResponse>('/auth/login', credentials, false).subscribe({
        next: (response) => {
          console.log('Login response:', response);
          console.log('Token in response:', response?.token);
          if (response?.token) {
            this.setToken(response.token);
            this.isAuthenticatedSubject.next(true);
            console.log('Token stored, isAuthenticated set to true');
          } else {
            console.error('No token in login response!', response);
          }
          observer.next(response);
          observer.complete();
        },
        error: (error) => {
          console.error('Login error:', error);
          observer.error(error);
        }
      });
    });
  }

  register(data: RegisterRequest): Observable<AuthResponse> {
    return new Observable(observer => {
      this.apiService.post<AuthResponse>('/auth/register', data, false).subscribe({
        next: (response) => {
          console.log('Register response:', response);
          console.log('Token in response:', response?.token);
          if (response?.token) {
            this.setToken(response.token);
            this.isAuthenticatedSubject.next(true);
            console.log('Token stored, isAuthenticated set to true');
          } else {
            console.error('No token in register response!', response);
          }
          observer.next(response);
          observer.complete();
        },
        error: (error) => {
          console.error('Register error:', error);
          observer.error(error);
        }
      });
    });
  }

  logout(): void {
    this.clearToken();
    this.router.navigate(['/welcome']);
  }

  clearToken(): void {
    localStorage.removeItem(this.tokenKey);
    this.isAuthenticatedSubject.next(false);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  private setToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
    // S'assurer que le token est bien stocké avant de continuer
    console.log('Token stored:', token ? 'Token saved (' + token.substring(0, 20) + '...)' : 'No token');
  }

  private hasToken(): boolean {
    return !!localStorage.getItem(this.tokenKey);
  }

  isAuthenticated(): boolean {
    const hasToken = this.hasToken();
    // S'assurer que l'observable est synchronisé avec l'état réel
    if (this.isAuthenticatedSubject.value !== hasToken) {
      this.isAuthenticatedSubject.next(hasToken);
    }
    return hasToken;
  }
}

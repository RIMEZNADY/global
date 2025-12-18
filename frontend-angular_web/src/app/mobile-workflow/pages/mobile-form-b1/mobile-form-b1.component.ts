import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { LocationService } from '../../../services/location.service';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-b1',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Activation GPS & Carte</div>
          <div class="mw-sub">NEW · Étape 1/5</div>
        </div>
      </div>

      <div class="mw-content">
        <div class="mw-card">
          <h2>Localisation</h2>
          <p class="mw-muted">Le web utilise l’API navigateur (GPS). Vous pouvez aussi choisir manuellement.</p>

          <div class="mw-actions">
            <button class="mw-btn" (click)="useGps()" [disabled]="isLoadingGps">
              <span *ngIf="!isLoadingGps">Activer la localisation</span>
              <span *ngIf="isLoadingGps">Chargement...</span>
            </button>
            <button class="mw-btn mw-alt" (click)="pickOnMap()">Choisir sur la carte</button>
          </div>

          <div class="mw-loc" *ngIf="lat != null && lng != null">
            <div><strong>Lat:</strong> {{ lat.toFixed(6) }} · <strong>Lng:</strong> {{ lng.toFixed(6) }}</div>
            <div *ngIf="irradiationClass"><strong>Zone:</strong> {{ irradiationClass }}</div>
          </div>

          <div class="mw-error" *ngIf="errorMessage">{{ errorMessage }}</div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" [disabled]="lat == null || lng == null" (click)="next()">Continuer</button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-page {
        min-height: 100vh;
        background: var(--off-white);
      }
      .mw-topbar {
        display: flex;
        gap: 12px;
        align-items: center;
        padding: 16px 18px;
        background: #fff;
        border-bottom: 1px solid rgba(0, 0, 0, 0.06);
      }
      .mw-back {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        background: #fff;
        cursor: pointer;
        font-size: 18px;
      }
      .mw-title {
        font-weight: 900;
      }
      .mw-sub {
        font-size: 12px;
        opacity: 0.7;
      }
      .mw-content {
        max-width: 960px;
        margin: 0 auto;
        padding: 16px;
        display: grid;
        gap: 16px;
      }
      .mw-card {
        background: #fff;
        border-radius: 16px;
        padding: 16px;
        border: 1px solid rgba(0, 0, 0, 0.06);
        box-shadow: 0 6px 18px rgba(0, 0, 0, 0.06);
      }
      .mw-card h2 {
        font-size: 18px;
        margin-bottom: 10px;
      }
      .mw-muted {
        font-size: 12px;
        opacity: 0.75;
        margin-bottom: 12px;
      }
      .mw-actions {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
      }
      .mw-btn {
        padding: 12px 18px;
        border-radius: 14px;
        border: none;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        font-weight: 900;
        cursor: pointer;
      }
      .mw-alt {
        background: linear-gradient(135deg, var(--solar-yellow), var(--medical-blue));
      }
      .mw-loc {
        margin-top: 12px;
        padding: 12px;
        border-radius: 12px;
        background: rgba(78, 168, 222, 0.06);
        border: 1px solid rgba(78, 168, 222, 0.18);
        font-size: 13px;
      }
      .mw-error {
        margin-top: 12px;
        color: var(--error);
        font-size: 13px;
      }
      .mw-footer {
        display: flex;
        justify-content: flex-end;
      }
      .mw-btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
      .mw-btn[disabled] {
        position: relative;
      }
    `
  ]
})
export class MobileFormB1Component {
  lat: number | null = null;
  lng: number | null = null;
  irradiationClass: string | null = null;
  errorMessage = '';
  isLoadingGps = false;

  constructor(private router: Router, private locationService: LocationService, private draft: MobileDraftService) {
    const saved = this.draft.get<any>('b1');
    if (saved?.lat != null && saved?.lng != null) {
      this.lat = saved.lat;
      this.lng = saved.lng;
      this.irradiationClass = saved.irradiationClass || null;
    }
  }

  useGps(): void {
    this.errorMessage = '';
    this.isLoadingGps = true;
    
    if (!navigator.geolocation) {
      this.errorMessage = 'Géolocalisation non supportée par ce navigateur.';
      this.isLoadingGps = false;
      return;
    }
    navigator.geolocation.getCurrentPosition(
      pos => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        
        // Vérifier si la position est au Maroc
        if (lat >= 20 && lat <= 36 && lng >= -17 && lng <= -1) {
          this.lat = lat;
          this.lng = lng;
          this.fetchZone();
        } else {
          this.errorMessage = 'Position hors du Maroc. Veuillez utiliser la carte pour sélectionner une localisation au Maroc.';
          this.isLoadingGps = false;
        }
      },
      err => {
        this.isLoadingGps = false;
        if (err.code === 1) {
          this.errorMessage = 'Permission de localisation refusée. Veuillez autoriser l\'accès à votre position ou choisir manuellement sur la carte.';
        } else if (err.code === 2) {
          this.errorMessage = 'Position indisponible. Veuillez vérifier votre connexion GPS ou choisir manuellement sur la carte.';
        } else if (err.code === 3) {
          this.errorMessage = 'Délai d\'attente dépassé. Veuillez réessayer ou choisir manuellement sur la carte.';
        } else {
          this.errorMessage = err.message || 'Impossible d’obtenir la localisation.';
        }
      },
      { 
        enableHighAccuracy: true, 
        timeout: 15000,
        maximumAge: 0
      }
    );
  }

  pickOnMap(): void {
    // Reuse MapSelection page and come back with lat/lng
    this.router.navigate(['/mobile/map-selection'], { queryParams: { next: '/mobile/b1' } });
  }

  private fetchZone(): void {
    if (this.lat == null || this.lng == null) {
      this.isLoadingGps = false;
      return;
    }
    this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
      next: res => {
        this.irradiationClass = res.irradiationClass;
        this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: this.irradiationClass });
        this.isLoadingGps = false;
      },
      error: () => {
        this.irradiationClass = null;
        this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: null });
        this.isLoadingGps = false;
      }
    });
  }

  next(): void {
    if (this.lat == null || this.lng == null) return;
    this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: this.irradiationClass });
    this.router.navigate(['/mobile/b2']);
  }

  back(): void {
    this.router.navigate(['/mobile/choice']);
  }
}


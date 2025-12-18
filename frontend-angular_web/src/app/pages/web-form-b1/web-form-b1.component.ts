import { Component, OnInit, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { LeafletModule } from '@asymmetrik/ngx-leaflet';
import { trigger, transition, style, animate } from '@angular/animations';
import { LocationService, IrradiationResponse } from '../../services/location.service';
import { MobileDraftService } from '../../mobile-workflow/services/mobile-draft.service';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';
import * as L from 'leaflet';

function createCustomIcon(zoneClass: string): L.DivIcon {
  const colors: { [key: string]: string } = {
    'A': '#FF6B35',
    'B': '#FFA726',
    'C': '#FFD54F',
    'D': '#90CAF9'
  };
  
  const color = colors[zoneClass] || '#4EA8DE';
  
  const html = `
    <div style="
      width: 32px;
      height: 32px;
      background: ${color};
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
      display: flex;
      align-items: center;
      justify-content: center;
    ">
      <div style="
        width: 12px;
        height: 12px;
        background: white;
        border-radius: 50%;
      "></div>
    </div>
  `;
  
  return L.divIcon({
    html: html,
    className: 'custom-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 16]
  });
}

@Component({
  selector: 'app-web-form-b1',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, LeafletModule, NavigationComponent, TooltipComponent],
  animations: [
    trigger('fadeInUp', [
      transition(':enter', [
        style({ opacity: 0, transform: 'translateY(20px)' }),
        animate('0.5s ease-out', style({ opacity: 1, transform: 'translateY(0)' }))
      ])
    ])
  ],
  template: `
    <div class="web-form-container">
      <app-navigation></app-navigation>
      <div class="web-form-content">
        <div class="page-header">
          <h1>Localisation du Projet</h1>
          <p>NEW · Étape 1/5 · Sélectionnez l'emplacement de votre établissement</p>
        </div>

        <div class="form-card">
          <div class="form-section">
            <h3>
              Sélection de la localisation
              <app-tooltip text="Sélectionnez l'emplacement géographique de votre établissement. La zone d'irradiation solaire sera déterminée automatiquement selon la position choisie."></app-tooltip>
            </h3>
            <p class="section-description">
              Utilisez votre position GPS ou choisissez manuellement sur la carte. La zone d'irradiation sera déterminée automatiquement.
            </p>

            <div class="location-actions">
              <button class="action-btn primary" (click)="useGps()" [disabled]="isLoadingLocation || !gpsAvailable">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                  <circle cx="12" cy="10" r="3"></circle>
                </svg>
                <span *ngIf="!isLoadingLocation">Activer la localisation GPS</span>
                <span *ngIf="isLoadingLocation">Chargement...</span>
              </button>
            </div>
            
            <div *ngIf="errorMessage" class="error-message" style="margin-top: 12px; padding: 12px; background: #fee; border: 1px solid #fcc; border-radius: 8px; color: #c33;">
              {{ errorMessage }}
            </div>

            <div class="map-container">
              <div *ngIf="isLoadingLocation" class="map-loading">
                <div class="spinner"></div>
                <p>Chargement de votre position...</p>
              </div>
              <div leaflet 
                   [leafletOptions]="mapOptions"
                   [leafletLayers]="mapLayers"
                   (leafletMapReady)="onMapReady($any($event))"
                   class="map">
              </div>
            </div>

          </div>

          <!-- Info Cards Section (like EXISTANT workflow) -->
          <div class="info-cards-section" *ngIf="lat != null && lng != null">
            <div class="info-cards">
              <!-- Carte Coordonnées -->
              <div class="info-card card-coords" [@fadeInUp]>
                <div class="card-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                    <circle cx="12" cy="10" r="3"></circle>
                  </svg>
                </div>
                <div class="card-content">
                  <div class="card-label">Coordonnées GPS</div>
                  <div class="card-value">
                    {{ lat.toFixed(6) }}, {{ lng.toFixed(6) }}
                  </div>
                </div>
              </div>

              <!-- Carte Zone d'irradiation -->
              <div class="info-card card-zone" *ngIf="irradiationData" [@fadeInUp] [style.animation-delay]="'0.1s'">
                <div class="card-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="5"></circle>
                    <path d="M12 1v6m0 6v6M23 12h-6m-6 0H1M19.07 4.93l-4.24 4.24m0 5.66l4.24 4.24M4.93 4.93l4.24 4.24m0 5.66l-4.24 4.24"></path>
                  </svg>
                </div>
                <div class="card-content">
                  <div class="card-label">Zone d'irradiation</div>
                  <div class="card-value">
                    {{ locationService.getZoneLabel(irradiationData.irradiationClass || '') }}
                  </div>
                </div>
                <div class="zone-badge" [attr.data-zone]="irradiationData.irradiationClass">
                  {{ irradiationData.irradiationClass }}
                </div>
              </div>

              <!-- Carte Ville -->
              <div class="info-card card-city" *ngIf="irradiationData && irradiationData.nearestCity" [@fadeInUp] [style.animation-delay]="'0.2s'">
                <div class="card-icon">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                    <path d="M9 10h6m-3-3v6"></path>
                  </svg>
                </div>
                <div class="card-content">
                  <div class="card-label">Ville la plus proche</div>
                  <div class="card-value">
                    {{ irradiationData.nearestCity.name }}
                  </div>
                  <div class="card-subvalue">
                    {{ irradiationData.nearestCity.region }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Bouton Continuer -->
            <div class="action-section">
              <button class="btn-continue" [disabled]="!lat || !lng || isLoadingLocation" (click)="next()" [@fadeInUp] [style.animation-delay]="'0.3s'">
                <span *ngIf="!isLoadingLocation">
                  <span>Continuer</span>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="9 18 15 12 9 6"></polyline>
                  </svg>
                </span>
                <span *ngIf="isLoadingLocation" class="btn-loading">
                  <div class="btn-spinner"></div>
                  <span>Chargement...</span>
                </span>
              </button>
            </div>
          </div>

          <div class="form-actions" *ngIf="lat == null || lng == null">
            <button type="button" class="btn-secondary" (click)="back()">Retour</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./web-form-b1.component.scss']
})
export class WebFormB1Component implements OnInit, AfterViewInit {
  lat: number | null = null;
  lng: number | null = null;
  irradiationClass: string | null = null;
  irradiationData: IrradiationResponse | null = null;
  errorMessage = '';
  isLoadingLocation = false;
  showMap = true;
  map: L.Map | null = null;
  marker: L.Marker | null = null;
  zoneCircle: L.Circle | null = null;
  gpsAvailable = true;

  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap contributors'
      })
    ],
    zoom: 6,
    center: L.latLng(31.7917, -7.0926)
  };

  mapLayers: L.Layer[] = [];

  constructor(
    private router: Router,
    public locationService: LocationService,
    private draft: MobileDraftService
  ) {
    const saved = this.draft.get<any>('b1');
    if (saved?.lat != null && saved?.lng != null) {
      this.lat = saved.lat;
      this.lng = saved.lng;
      this.irradiationClass = saved.irradiationClass || null;
      this.mapOptions.center = L.latLng(saved.lat, saved.lng);
      this.mapOptions.zoom = 12;
      // Charger les données d'irradiation si on a déjà une position
      if (this.irradiationClass && this.lat != null && this.lng != null) {
        this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
          next: (res) => {
            this.irradiationData = res;
          },
          error: () => {
            this.irradiationData = null;
          }
        });
      }
    }
  }

  ngOnInit(): void {
    // Vérifier la permission de géolocalisation au démarrage
    if (navigator.geolocation && 'permissions' in navigator) {
      (navigator.permissions as any).query({ name: 'geolocation' }).then((result: PermissionStatus) => {
        if (result.state === 'denied') {
          this.gpsAvailable = false;
        }
        // Écouter les changements de permission
        result.onchange = () => {
          this.gpsAvailable = result.state !== 'denied';
        };
      }).catch(() => {
        // Si l'API permissions n'est pas supportée, on laisse gpsAvailable à true
      });
    } else if (!navigator.geolocation) {
      this.gpsAvailable = false;
    }
    
    // Essayer de centrer la carte sur la position si disponible (sans afficher d'erreur)
    if (navigator.geolocation && this.gpsAvailable) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          if (lat >= 20 && lat <= 36 && lng >= -17 && lng <= -1) {
            this.mapOptions.center = L.latLng(lat, lng);
            this.mapOptions.zoom = 12;
          }
        },
        () => {
          // Erreur silencieuse - ne rien faire
        }
      );
    }
  }

  ngAfterViewInit(): void {
    // La carte sera initialisée via leafletMapReady
  }

  onMapReady(map: L.Map): void {
    this.map = map;
    
    map.on('click', (e: L.LeafletMouseEvent) => {
      this.onMapClick(e.latlng);
    });

    // Si on a déjà une position, centrer la carte et afficher le marqueur
    if (this.lat != null && this.lng != null) {
      // Centrer la carte sur la position
      map.setView([this.lat, this.lng], 12);
      
      if (this.irradiationClass) {
        // Si on a déjà la zone, afficher directement
        this.updateMapWithLocation(this.lat, this.lng, this.irradiationClass);
      } else {
        // Si on a la position mais pas encore la zone, récupérer la zone
        this.fetchZone();
      }
    }
  }

  useGps(): void {
    this.errorMessage = '';
    this.isLoadingLocation = true;
    
    if (!navigator.geolocation) {
      this.gpsAvailable = false;
      this.isLoadingLocation = false;
      this.errorMessage = 'Géolocalisation non supportée par ce navigateur. Veuillez choisir manuellement sur la carte.';
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        
        // Vérifier si la position est au Maroc
        if (lat >= 20 && lat <= 36 && lng >= -17 && lng <= -1) {
          this.lat = lat;
          this.lng = lng;
          // Mettre à jour les options de la carte pour centrer sur la position
          this.mapOptions.center = L.latLng(lat, lng);
          this.mapOptions.zoom = 12;
          // Centrer la carte sur la position si elle est déjà prête
          if (this.map) {
            this.map.setView([lat, lng], 12);
          }
          // Récupérer la zone d'irradiation (qui mettra à jour la carte avec le marqueur)
          this.fetchZone();
        } else {
          // Position hors du Maroc
          this.isLoadingLocation = false;
          this.errorMessage = 'Position hors du Maroc. Veuillez sélectionner une localisation au Maroc sur la carte.';
        }
      },
      (err) => {
        this.isLoadingLocation = false;
        // Désactiver le GPS si permission refusée de manière permanente
        if (err.code === 1 || err.code === err.PERMISSION_DENIED) {
          this.gpsAvailable = false;
          this.errorMessage = 'Permission de localisation refusée. Veuillez autoriser l\'accès à votre position ou choisir manuellement sur la carte.';
        } else if (err.code === 2) {
          this.errorMessage = 'Position indisponible. Veuillez vérifier votre connexion GPS ou choisir manuellement sur la carte.';
        } else if (err.code === 3) {
          this.errorMessage = 'Délai d\'attente dépassé. Veuillez réessayer ou choisir manuellement sur la carte.';
        } else {
          this.errorMessage = 'Impossible d\'obtenir la localisation. Veuillez choisir manuellement sur la carte.';
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
    this.errorMessage = '';
    if (this.map) {
      this.map.invalidateSize();
    }
  }

  onMapClick(latlng: L.LatLng): void {
    this.lat = latlng.lat;
    this.lng = latlng.lng;
    this.isLoadingLocation = true;
    this.errorMessage = '';
    this.fetchZone();
  }

  private fetchZone(): void {
    if (this.lat == null || this.lng == null) return;
    
    this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
      next: (res) => {
        this.irradiationClass = res.irradiationClass;
        this.irradiationData = res;
        this.updateMapWithLocation(this.lat!, this.lng!, res.irradiationClass);
        this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: this.irradiationClass });
        this.isLoadingLocation = false;
      },
      error: () => {
        this.irradiationClass = null;
        this.irradiationData = null;
        this.isLoadingLocation = false;
        this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: null });
      }
    });
  }

  updateMapWithLocation(lat: number, lng: number, zoneClass: string): void {
    if (!this.map) {
      setTimeout(() => this.updateMapWithLocation(lat, lng, zoneClass), 100);
      return;
    }

    if (this.marker && this.map) {
      this.map.removeLayer(this.marker);
    }
    if (this.zoneCircle && this.map) {
      this.map.removeLayer(this.zoneCircle);
    }

    const zoneConfig: { [key: string]: { color: string, radius: number } } = {
      'A': { color: '#FF6B35', radius: 50000 },
      'B': { color: '#FFA726', radius: 40000 },
      'C': { color: '#FFD54F', radius: 30000 },
      'D': { color: '#90CAF9', radius: 25000 }
    };

    const config = zoneConfig[zoneClass] || zoneConfig['C'];

    this.zoneCircle = L.circle([lat, lng], {
      radius: config.radius,
      color: config.color,
      fillColor: config.color,
      fillOpacity: 0.2,
      weight: 3,
      opacity: 0.6
    }).addTo(this.map);

    this.marker = L.marker([lat, lng], {
      icon: createCustomIcon(zoneClass)
    }).addTo(this.map);

    const bounds = this.zoneCircle.getBounds();
    this.map.fitBounds(bounds, { padding: [50, 50] });
  }

  next(): void {
    if (this.lat == null || this.lng == null) return;
    this.draft.set('b1', { lat: this.lat, lng: this.lng, irradiationClass: this.irradiationClass });
    this.router.navigate(['/web/b2']);
  }

  back(): void {
    this.router.navigate(['/institution-choice']);
  }
}


import { Component, NgZone, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { trigger, state, style, transition, animate } from '@angular/animations';
import * as L from 'leaflet';
import { LocationService, IrradiationResponse } from '../../../services/location.service';

@Component({
  selector: 'app-mobile-map-selection',
  animations: [
    trigger('fadeInUp', [
      transition(':enter', [
        style({ opacity: 0, transform: 'translateY(20px)' }),
        animate('0.5s ease-out', style({ opacity: 1, transform: 'translateY(0)' }))
      ])
    ])
  ],
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Sélection de localisation</div>
          <div class="mw-sub">Choisissez l'emplacement de votre établissement sur la carte</div>
        </div>
      </div>

      <!-- Message de permission -->
      <div class="mw-permission-banner" *ngIf="showPermissionMessage && !hasPermission">
        <div class="mw-permission-content">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
          </svg>
          <div>
            <strong>Autorisation de localisation requise</strong>
            <p>Pour une meilleure expérience, autorisez l'accès à votre position GPS</p>
          </div>
          <button class="mw-permission-btn" (click)="requestLocationPermission()">Autoriser</button>
        </div>
      </div>

      <div class="mw-map-wrap">
        <div *ngIf="isLoadingLocation" class="mw-loading-overlay">
          <div class="mw-spinner"></div>
          <p>Chargement de votre position...</p>
        </div>
        <div
          leaflet
          class="mw-map"
          [leafletOptions]="mapOptions"
          [leafletLayers]="mapLayers"
          (leafletMapReady)="onMapReady($event)"
        ></div>
      </div>

      <div class="mw-bottom" *ngIf="selectedLocation">
        <div class="mw-info-cards">
          <!-- Carte Coordonnées -->
          <div class="mw-info-card mw-card-coords" [@fadeInUp]>
            <div class="mw-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                <circle cx="12" cy="10" r="3"></circle>
              </svg>
            </div>
            <div class="mw-card-content">
              <div class="mw-card-label">Coordonnées GPS</div>
              <div class="mw-card-value">
                {{ selectedLocation.lat.toFixed(6) }}, {{ selectedLocation.lng.toFixed(6) }}
              </div>
            </div>
          </div>

          <!-- Carte Zone d'irradiation -->
          <div class="mw-info-card mw-card-zone" *ngIf="irradiationData" [@fadeInUp] [style.animation-delay]="'0.1s'">
            <div class="mw-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="5"></circle>
                <path d="M12 1v6m0 6v6M23 12h-6m-6 0H1M19.07 4.93l-4.24 4.24m0 5.66l4.24 4.24M4.93 4.93l4.24 4.24m0 5.66l-4.24 4.24"></path>
              </svg>
            </div>
            <div class="mw-card-content">
              <div class="mw-card-label">Zone d'irradiation</div>
              <div class="mw-card-value">
                {{ locationService.getZoneLabel(irradiationData.irradiationClass || '') }}
              </div>
            </div>
            <div class="mw-zone-badge" [attr.data-zone]="irradiationData.irradiationClass">
              {{ irradiationData.irradiationClass }}
            </div>
          </div>

          <!-- Carte Ville -->
          <div class="mw-info-card mw-card-city" *ngIf="irradiationData && irradiationData.nearestCity" [@fadeInUp] [style.animation-delay]="'0.2s'">
            <div class="mw-card-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                <path d="M9 10h6m-3-3v6"></path>
              </svg>
            </div>
            <div class="mw-card-content">
              <div class="mw-card-label">Ville la plus proche</div>
              <div class="mw-card-value">
                {{ irradiationData.nearestCity.name }}
              </div>
              <div class="mw-card-subvalue">
                {{ irradiationData.nearestCity.region }}
              </div>
            </div>
          </div>
        </div>

        <!-- Bouton Continuer -->
        <div class="mw-action-section">
          <button class="mw-btn" [disabled]="!selectedLocation || isLoadingLocation" (click)="continue()" [@fadeInUp] [style.animation-delay]="'0.3s'">
            <span *ngIf="!isLoadingLocation">
              <span>Continuer</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </span>
            <span *ngIf="isLoadingLocation" class="mw-btn-loading">
              <div class="mw-btn-spinner"></div>
              <span>Chargement...</span>
            </span>
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mw-page {
        min-height: 100vh;
        background: var(--off-white);
        display: flex;
        flex-direction: column;
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
        font-weight: 800;
      }
      .mw-sub {
        font-size: 12px;
        opacity: 0.7;
      }
      .mw-map-wrap {
        flex: 1;
        padding: 16px;
      }
      .mw-map {
        width: 100%;
        height: 100%;
        min-height: 420px;
        border-radius: 16px;
        overflow: hidden;
        border: 2px solid rgba(78, 168, 222, 0.18);
      }
      .mw-bottom {
        padding: 24px 20px;
        background: linear-gradient(180deg, rgba(255, 255, 255, 0.95), rgba(248, 250, 252, 0.98));
        border-top: 1px solid rgba(78, 168, 222, 0.1);
        box-shadow: 0 -4px 20px rgba(78, 168, 222, 0.08);
        display: flex;
        flex-direction: column;
        gap: 20px;
        min-height: 200px;
      }
      .mw-info-cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 16px;
        width: 100%;
      }
      .mw-info-card {
        background: white;
        border-radius: 16px;
        padding: 20px;
        display: flex;
        align-items: flex-start;
        gap: 16px;
        box-shadow: 0 4px 16px rgba(78, 168, 222, 0.12);
        border: 1px solid rgba(78, 168, 222, 0.1);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
      }
      .mw-info-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 4px;
        background: linear-gradient(90deg, var(--medical-blue), var(--solar-green));
        transform: scaleX(0);
        transform-origin: left;
        transition: transform 0.4s ease;
      }
      .mw-info-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 24px rgba(78, 168, 222, 0.2);
      }
      .mw-info-card:hover::before {
        transform: scaleX(1);
      }
      .mw-card-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        background: linear-gradient(135deg, rgba(78, 168, 222, 0.1), rgba(76, 175, 80, 0.1));
        color: var(--medical-blue);
        transition: all 0.3s ease;
      }
      .mw-info-card:hover .mw-card-icon {
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: white;
        transform: scale(1.1) rotate(5deg);
      }
      .mw-card-icon svg {
        width: 24px;
        height: 24px;
      }
      .mw-card-content {
        flex: 1;
        min-width: 0;
      }
      .mw-card-label {
        font-size: 11px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: var(--soft-grey);
        margin-bottom: 6px;
        opacity: 0.8;
      }
      .mw-card-value {
        font-size: 15px;
        font-weight: 700;
        color: var(--medical-blue);
        line-height: 1.4;
        word-break: break-word;
      }
      .mw-card-subvalue {
        font-size: 12px;
        color: var(--soft-grey);
        margin-top: 4px;
        opacity: 0.7;
      }
      .mw-zone-badge {
        position: absolute;
        top: 12px;
        right: 12px;
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 14px;
        color: white;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        box-shadow: 0 2px 8px rgba(78, 168, 222, 0.3);
        animation: pulse 2s ease-in-out infinite;
      }
      .mw-zone-badge[data-zone="A"] {
        background: linear-gradient(135deg, #f59e0b, #ef4444);
      }
      .mw-zone-badge[data-zone="B"] {
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
      }
      .mw-zone-badge[data-zone="C"] {
        background: linear-gradient(135deg, #3b82f6, #60a5fa);
      }
      .mw-zone-badge[data-zone="D"] {
        background: linear-gradient(135deg, #8b5cf6, #a78bfa);
      }
      @keyframes pulse {
        0%, 100% {
          transform: scale(1);
          box-shadow: 0 2px 8px rgba(78, 168, 222, 0.3);
        }
        50% {
          transform: scale(1.05);
          box-shadow: 0 4px 12px rgba(78, 168, 222, 0.5);
        }
      }
      .mw-action-section {
        width: 100%;
        display: flex;
        justify-content: center;
        padding-top: 8px;
      }
      .mw-btn {
        padding: 16px 32px;
        border-radius: 16px;
        border: none;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: #fff;
        font-weight: 700;
        font-size: 16px;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 10px;
        box-shadow: 0 6px 20px rgba(78, 168, 222, 0.4);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
        min-width: 200px;
        justify-content: center;
      }
      .mw-btn::before {
        content: '';
        position: absolute;
        top: 50%;
        left: 50%;
        width: 0;
        height: 0;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.3);
        transform: translate(-50%, -50%);
        transition: width 0.6s, height 0.6s;
      }
      .mw-btn:hover:not(:disabled) {
        transform: translateY(-2px);
        box-shadow: 0 8px 28px rgba(78, 168, 222, 0.5);
      }
      .mw-btn:hover:not(:disabled)::before {
        width: 300px;
        height: 300px;
      }
      .mw-btn:active:not(:disabled) {
        transform: translateY(0);
      }
      .mw-btn svg {
        width: 20px;
        height: 20px;
        position: relative;
        z-index: 1;
        transition: transform 0.3s ease;
      }
      .mw-btn:hover:not(:disabled) svg {
        transform: translateX(4px);
      }
      .mw-btn span {
        position: relative;
        z-index: 1;
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .mw-btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none;
      }
      .mw-btn-loading {
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .mw-btn-spinner {
        width: 16px;
        height: 16px;
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-top-color: white;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
      }
      .mw-permission-banner {
        background: linear-gradient(135deg, rgba(78, 168, 222, 0.1), rgba(76, 175, 80, 0.1));
        border-bottom: 1px solid rgba(78, 168, 222, 0.2);
        padding: 16px;
      }
      .mw-permission-content {
        display: flex;
        align-items: center;
        gap: 12px;
        max-width: 1200px;
        margin: 0 auto;
      }
      .mw-permission-content svg {
        color: var(--medical-blue);
        flex-shrink: 0;
      }
      .mw-permission-content > div {
        flex: 1;
      }
      .mw-permission-content strong {
        display: block;
        color: var(--medical-blue);
        font-size: 14px;
        margin-bottom: 4px;
      }
      .mw-permission-content p {
        font-size: 12px;
        color: var(--soft-grey);
        margin: 0;
      }
      .mw-permission-btn {
        padding: 8px 16px;
        background: linear-gradient(135deg, var(--medical-blue), var(--solar-green));
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: transform 0.2s;
      }
      .mw-permission-btn:hover {
        transform: translateY(-1px);
      }
      .mw-loading-overlay {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(255, 255, 255, 0.9);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 12px;
        z-index: 1000;
        border-radius: 16px;
      }
      .mw-spinner {
        width: 40px;
        height: 40px;
        border: 4px solid rgba(78, 168, 222, 0.2);
        border-top-color: var(--medical-blue);
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      @keyframes spin {
        to { transform: rotate(360deg); }
      }
    `
  ]
})
export class MobileMapSelectionComponent implements OnInit {
  map: L.Map | null = null;
  marker: L.Marker | null = null;
  zoneCircle: L.Circle | null = null;
  selectedLocation: L.LatLng | null = null;
  irradiationData: IrradiationResponse | null = null;
  isLoadingLocation = false;
  hasPermission = false;
  showPermissionMessage = true;
  
  private markerIcon = L.icon({
    iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
    iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
    shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  });

  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap contributors'
      })
    ],
    zoom: 6,
    center: L.latLng(33.5731, -7.5898) // Casablanca par défaut
  };
  mapLayers: L.Layer[] = [];

  constructor(
    private router: Router, 
    private route: ActivatedRoute, 
    private zone: NgZone,
    public locationService: LocationService
  ) {}

  ngOnInit(): void {
    this.checkLocationPermission();
  }

  checkLocationPermission(): void {
    if (!navigator.geolocation) {
      this.hasPermission = false;
      this.showPermissionMessage = true;
      return;
    }
    
    // Vérifier si la permission a déjà été accordée
    if (navigator.permissions && 'query' in navigator.permissions) {
      (navigator.permissions as any).query({ name: 'geolocation' }).then((result: PermissionStatus) => {
        this.hasPermission = result.state === 'granted';
        this.showPermissionMessage = result.state === 'prompt' || result.state === 'denied';
        
        if (this.hasPermission) {
          // Si la permission est déjà accordée, obtenir la localisation automatiquement
          this.getCurrentLocation();
        }
        
        // Écouter les changements de permission
        result.onchange = () => {
          this.hasPermission = result.state === 'granted';
          this.showPermissionMessage = result.state === 'prompt' || result.state === 'denied';
          if (this.hasPermission) {
            this.getCurrentLocation();
          }
        };
      }).catch(() => {
        // Fallback pour les navigateurs qui ne supportent pas permissions API
        // Essayer d'obtenir la localisation directement
        this.getCurrentLocation();
      });
    } else {
      // Fallback pour les navigateurs qui ne supportent pas l'API permissions
      // Essayer d'obtenir la localisation directement
      this.getCurrentLocation();
    }
  }

  requestLocationPermission(): void {
    this.showPermissionMessage = false;
    this.getCurrentLocation();
  }

  getCurrentLocation(): void {
    if (!navigator.geolocation) {
      this.hasPermission = false;
      this.showPermissionMessage = true;
      return;
    }

    this.isLoadingLocation = true;
    this.showPermissionMessage = false;

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude;
        const lng = position.coords.longitude;
        
        // Vérifier si la position est au Maroc (latitude 20-36, longitude -17 à -1)
        if (lat >= 20 && lat <= 36 && lng >= -17 && lng <= -1) {
          this.selectedLocation = L.latLng(lat, lng);
          this.mapOptions.center = L.latLng(lat, lng);
          this.mapOptions.zoom = 12;
          
          // Si la carte est déjà prête, mettre à jour immédiatement
          if (this.map) {
            this.map.setView([lat, lng], 12);
            this.updateMarker(this.selectedLocation);
            this.loadIrradiationData(lat, lng);
          } else {
            // Si la carte n'est pas encore prête, charger les données quand même
            this.loadIrradiationData(lat, lng);
          }
        } else {
          // Position hors Maroc, utiliser Casablanca par défaut
          this.mapOptions.center = L.latLng(33.5731, -7.5898);
          this.mapOptions.zoom = 12;
          if (this.map) {
            this.map.setView([33.5731, -7.5898], 12);
          }
          this.isLoadingLocation = false;
        }
        
        this.hasPermission = true;
      },
      (error) => {
        console.error('Erreur de géolocalisation:', error);
        this.hasPermission = false;
        this.showPermissionMessage = true;
        this.isLoadingLocation = false;
        
        // Centrer sur Casablanca par défaut
        this.mapOptions.center = L.latLng(33.5731, -7.5898);
        this.mapOptions.zoom = 12;
        if (this.map) {
          this.map.setView([33.5731, -7.5898], 12);
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 0
      }
    );
  }

  onMapReady(map: L.Map): void {
    this.map = map;
    
    // Centrer sur la position initiale
    if (this.mapOptions.center) {
      map.setView(this.mapOptions.center, this.mapOptions.zoom || 12);
    }
    
    // Si on a déjà une position GPS sélectionnée, mettre à jour la carte
    if (this.selectedLocation) {
      map.setView([this.selectedLocation.lat, this.selectedLocation.lng], 12);
      this.updateMarker(this.selectedLocation);
    }
    
    map.on('click', (e: L.LeafletMouseEvent) => {
      this.zone.run(() => {
        this.selectedLocation = e.latlng;
        this.updateMarker(e.latlng);
        this.loadIrradiationData(e.latlng.lat, e.latlng.lng);
      });
    });
    
    // Si on a déjà une position GPS mais pas encore de données, charger les données
    if (this.selectedLocation && !this.irradiationData) {
      this.loadIrradiationData(this.selectedLocation.lat, this.selectedLocation.lng);
    }
  }

  updateMarker(latlng: L.LatLng): void {
    if (!this.map) return;
    
    if (this.marker) {
      this.map.removeLayer(this.marker);
    }
    
    this.marker = L.marker([latlng.lat, latlng.lng], { icon: this.markerIcon }).addTo(this.map);
    
    // Ajouter un cercle pour la zone
    if (this.zoneCircle) {
      this.map.removeLayer(this.zoneCircle);
    }
    
    this.zoneCircle = L.circle([latlng.lat, latlng.lng], {
      radius: 5000, // 5km
      color: '#4EA8DE',
      fillColor: '#4EA8DE',
      fillOpacity: 0.1,
      weight: 2
    }).addTo(this.map);
  }

  loadIrradiationData(lat: number, lng: number): void {
    this.isLoadingLocation = true;
    
    this.locationService.getIrradiationClass(lat, lng).subscribe({
      next: (data) => {
        this.irradiationData = data;
        this.isLoadingLocation = false;
      },
      error: (error) => {
        console.error('Erreur lors du chargement de la zone:', error);
        this.isLoadingLocation = false;
      }
    });
  }

  continue(): void {
    if (!this.selectedLocation) return;
    
    const next = this.route.snapshot.queryParamMap.get('next') || '/mobile/a1';
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    
    const queryParams: any = {
      lat: this.selectedLocation.lat,
      lng: this.selectedLocation.lng
    };
    
    if (establishmentId) {
      queryParams.establishmentId = establishmentId;
    }
    
    if (workflow) {
      queryParams.workflow = workflow;
    }
    
    if (this.irradiationData) {
      queryParams.irradiationClass = this.irradiationData.irradiationClass;
    }
    
    this.router.navigate([next], { queryParams });
  }

  back(): void {
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    if (establishmentId) {
      // Si on vient d'un établissement existant, retourner à la liste
      this.router.navigate(['/establishments']);
    } else {
      // Sinon, retourner au choix d'institution
      this.router.navigate(['/mobile/choice']);
    }
  }
}



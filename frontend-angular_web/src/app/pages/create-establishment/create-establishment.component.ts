import { Component, OnInit, AfterViewInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { LeafletModule } from '@asymmetrik/ngx-leaflet';
import { EstablishmentService } from '../../services/establishment.service';
import { LocationService, IrradiationResponse } from '../../services/location.service';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import * as L from 'leaflet';
import { icon, Icon } from 'leaflet';

// Créer une icône personnalisée pour le marqueur
function createCustomIcon(zoneClass: string): L.DivIcon {
  const colors: { [key: string]: string } = {
    'A': '#FF6B35', // Orange vif
    'B': '#FFA726', // Orange
    'C': '#FFD54F', // Jaune
    'D': '#90CAF9'  // Bleu clair
  };
  
  const color = colors[zoneClass] || '#4EA8DE';
  
  // Créer une icône HTML personnalisée
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
  selector: 'app-create-establishment',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, TooltipComponent, NavigationComponent, LeafletModule],
  template: `
    <div class="create-establishment-container">
      <app-navigation></app-navigation>
      <div class="create-establishment-content">
        <div class="page-header">
          <h1>{{ isEditMode ? 'Modifier l\'établissement' : 'Créer un établissement' }}</h1>
          <p>{{ isEditMode ? 'Modifiez les informations de votre établissement' : 'Configurez votre établissement pour commencer à utiliser l\'application' }}</p>
        </div>
        
        <form [formGroup]="establishmentForm" (ngSubmit)="onSubmit()" class="establishment-form">
          <div class="form-section">
            <h3>Informations de base</h3>
            
            <div class="form-group">
              <label class="form-label">
                Nom de l'établissement *
                <app-tooltip text="Le nom officiel de votre établissement de santé. Ce nom sera utilisé dans tous les rapports et analyses."></app-tooltip>
              </label>
              <input type="text" formControlName="name" placeholder="Ex: Hôpital Ibn Sina" class="form-input" />
              <span class="error" *ngIf="establishmentForm.get('name')?.hasError('required') && establishmentForm.get('name')?.touched">
                Le nom est requis
              </span>
            </div>
            
            <div class="form-group">
              <label class="form-label">
                Type d'établissement *
                <app-tooltip text="Sélectionnez le type d'établissement de santé qui correspond le mieux à votre structure. Cela influence les calculs et recommandations."></app-tooltip>
              </label>
              <select formControlName="type" class="form-input">
                <option value="">Sélectionnez un type</option>
                <optgroup *ngFor="let group of establishmentTypeGroups" [label]="group.label">
                  <option *ngFor="let opt of group.options" [value]="opt.value">{{ opt.label }}</option>
                </optgroup>
              </select>
              <span class="error" *ngIf="establishmentForm.get('type')?.hasError('required') && establishmentForm.get('type')?.touched">
                Le type est requis
              </span>
            </div>
            
            <div class="form-group">
              <label class="form-label">
                Nombre de lits *
                <app-tooltip text="Le nombre total de lits disponibles dans votre établissement. Cette information est utilisée pour estimer la consommation énergétique."></app-tooltip>
              </label>
              <input 
                type="number" 
                formControlName="numberOfBeds" 
                placeholder="Ex: 100" 
                min="1" 
                step="1"
                inputmode="numeric"
                pattern="[0-9]*"
                class="form-input number-input" />
              <span class="error" *ngIf="establishmentForm.get('numberOfBeds')?.hasError('required') && establishmentForm.get('numberOfBeds')?.touched">
                Le nombre de lits est requis
              </span>
              <span class="error" *ngIf="establishmentForm.get('numberOfBeds')?.hasError('min') && establishmentForm.get('numberOfBeds')?.touched">
                Le nombre de lits doit être supérieur à 0
              </span>
            </div>
          </div>
          
          <div class="form-section">
            <h3>Sélection de la localisation</h3>
            <p class="section-description">Cliquez sur la carte pour sélectionner l'emplacement de votre établissement. La zone d'irradiation sera déterminée automatiquement.</p>
            
            <div class="map-container">
              <div *ngIf="isLoadingLocation" class="map-loading">
                <p>Chargement de la carte...</p>
              </div>
              <div leaflet 
                   [leafletOptions]="mapOptions"
                   [leafletLayers]="mapLayers"
                   (leafletMapReady)="onMapReady($any($event))"
                   class="map">
              </div>
            </div>
            
            <div *ngIf="selectedLocation || (isEditMode && irradiationData)" class="location-info">
              <div class="info-card" [class]="'zone-' + (irradiationData?.irradiationClass || '').toLowerCase()">
                <div class="info-header">
                  <span class="info-icon"></span>
                  <div>
                    <strong>Position sélectionnée</strong>
                    <p *ngIf="irradiationData?.nearestCity">
                      {{ irradiationData?.nearestCity?.name }}, {{ irradiationData?.nearestCity?.region }}
                    </p>
                    <p *ngIf="!irradiationData?.nearestCity && selectedLocation">
                      {{ selectedLocation.lat.toFixed(4) }}, {{ selectedLocation.lng.toFixed(4) }}
                    </p>
                    <p *ngIf="!irradiationData?.nearestCity && !selectedLocation && irradiationData">
                      {{ irradiationData.latitude.toFixed(4) }}, {{ irradiationData.longitude.toFixed(4) }}
                    </p>
                  </div>
                </div>
                <div *ngIf="irradiationData" class="zone-info">
                  <strong>Zone d'irradiation: {{ locationService.getZoneLabel(irradiationData.irradiationClass) }}</strong>
                </div>
              </div>
            </div>
            
            <div class="form-group">
              <label>Adresse</label>
              <input 
                type="text" 
                formControlName="address" 
                [value]="addressFromMap || establishmentForm.get('address')?.value" 
                placeholder="Sera remplie automatiquement depuis la carte" 
                [readonly]="!isEditMode && selectedLocation" />
              <span class="help-text">
                <span *ngIf="!isEditMode">L'adresse est déterminée automatiquement depuis la position sur la carte</span>
                <span *ngIf="isEditMode">Vous pouvez modifier l'adresse si nécessaire</span>
              </span>
            </div>
          </div>
          
          <div class="form-section" *ngIf="irradiationData || (isEditMode && establishmentForm.get('irradiationClass')?.value)">
            <h3>Configuration énergétique</h3>
            
            <div class="zone-display" *ngIf="irradiationData">
              <div class="zone-info-card" [class]="'zone-' + irradiationData.irradiationClass.toLowerCase()">
                <div class="zone-header">
                  <span class="zone-icon"></span>
                  <div>
                    <strong>Zone d'irradiation déterminée</strong>
                    <p>{{ locationService.getZoneLabel(irradiationData.irradiationClass) }}</p>
                  </div>
                </div>
                <p class="zone-description">
                  Cette zone a été déterminée automatiquement depuis la base de données des villes marocaines selon la position sélectionnée sur la carte.
                </p>
              </div>
            </div>
            
            <div class="zone-display" *ngIf="!irradiationData && isEditMode && establishmentForm.get('irradiationClass')?.value">
              <div class="zone-info-card" [class]="'zone-' + establishmentForm.get('irradiationClass')?.value?.toLowerCase()">
                <div class="zone-header">
                  <span class="zone-icon"></span>
                  <div>
                    <strong>Zone d'irradiation</strong>
                    <p>{{ locationService.getZoneLabel(establishmentForm.get('irradiationClass')?.value) }}</p>
                  </div>
                </div>
                <p class="zone-description">
                  Zone d'irradiation de l'établissement. Vous pouvez modifier la position sur la carte pour changer la zone.
                </p>
              </div>
            </div>
            
            <div class="form-group">
              <label class="form-label">
                Surface installable (m²)
                <app-tooltip text="La surface totale disponible sur les toits ou au sol pour l'installation de panneaux photovoltaïques. Environ 5 m² sont nécessaires par kWc."></app-tooltip>
              </label>
              <input type="number" formControlName="installableSurfaceM2" placeholder="Ex: 5000" min="0" step="0.01" class="form-input" />
              <span class="help-text">Surface disponible pour l'installation de panneaux solaires</span>
            </div>
            
            <div class="form-group">
              <label class="form-label">
                Consommation mensuelle (kWh)
                <app-tooltip text="La consommation électrique mensuelle moyenne de votre établissement. Si non renseignée, elle sera estimée automatiquement en fonction du nombre de lits et du type d'établissement."></app-tooltip>
              </label>
              <input type="number" formControlName="monthlyConsumptionKwh" placeholder="Ex: 50000" min="0" step="0.01" class="form-input" />
              <span class="help-text">Si non renseigné, sera estimée automatiquement</span>
            </div>
          </div>
          
          <div class="error-message" *ngIf="errorMessage" [class.warning]="isEditMode">
            <div class="error-content">
              <span>{{ errorMessage }}</span>
              <span class="error-note" *ngIf="isEditMode">Vous pouvez quand même modifier les informations ci-dessus.</span>
            </div>
          </div>
          
          <div class="form-actions">
            <button type="button" class="btn-secondary" (click)="cancel()">
              Annuler
            </button>
            <button type="submit" class="btn-primary" [disabled]="establishmentForm.invalid || isLoading || (!selectedLocation && !isEditMode && !irradiationData)">
              <span *ngIf="!isLoading">{{ isEditMode ? 'Enregistrer les modifications' : 'Créer l\'établissement' }}</span>
              <span *ngIf="isLoading">{{ isEditMode ? 'Enregistrement en cours...' : 'Création en cours...' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  `,
  styleUrls: ['./create-establishment.component.scss']
})
export class CreateEstablishmentComponent implements OnInit, AfterViewInit {
  establishmentForm: FormGroup;
  isLoading = false;
  isLoadingLocation = false;
  errorMessage = '';
  selectedLocation: L.LatLng | null = null;
  irradiationData: IrradiationResponse | null = null;
  addressFromMap = '';
  map: L.Map | null = null;
  marker: L.Marker | null = null;
  zoneCircle: L.Circle | null = null;
  isEditMode = false;
  establishmentId: number | null = null;

  establishmentTypeGroups: Array<{
    label: string;
    options: Array<{ value: string; label: string }>;
  }> = [
    {
      label: 'Hôpitaux',
      options: [
        { value: 'CHU', label: 'CHU (Centre Hospitalo-Universitaire)' },
        { value: 'HOPITAL_REGIONAL', label: 'Hôpital Régional' },
        { value: 'HOPITAL_PREFECTORAL', label: 'Hôpital Préfectoral' },
        { value: 'HOPITAL_PROVINCIAL', label: 'Hôpital Provincial' }
      ]
    },
    {
      label: 'Centres spécialisés',
      options: [
        { value: 'CENTRE_REGIONAL_ONCOLOGIE', label: "Centre Régional d'Oncologie" },
        { value: 'CENTRE_HEMODIALYSE', label: "Centre d'Hémodialyse" },
        { value: 'CENTRE_REEDUCATION', label: 'Centre de Rééducation' },
        { value: 'CENTRE_ADDICTOLOGIE', label: "Centre d'Addictologie" },
        { value: 'CENTRE_SOINS_PALLIATIFS', label: 'Centre de Soins Palliatifs' }
      ]
    },
    {
      label: 'Urgences',
      options: [
        { value: 'UMH', label: 'UMH (Urgences médico-hospitalières)' },
        { value: 'UMP', label: 'UMP (Urgences médicales de proximité)' },
        { value: 'UPH', label: 'UPH (Urgences pré-hospitalières)' }
      ]
    },
    {
      label: 'Soins de proximité',
      options: [{ value: 'CENTRE_SANTE_PRIMAIRE', label: 'Centre de Santé Primaire' }]
    },
    {
      label: 'Privé',
      options: [{ value: 'CLINIQUE_PRIVEE', label: 'Clinique Privée' }]
    }
  ];

  // Options de la carte - centrée sur le Maroc
  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap contributors'
      })
    ],
    zoom: 6,
    center: L.latLng(31.7917, -7.0926) // Centre du Maroc
  };

  mapLayers: L.Layer[] = [];

  constructor(
    private fb: FormBuilder,
    private establishmentService: EstablishmentService,
    public locationService: LocationService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.establishmentForm = this.fb.group({
      name: ['', [Validators.required]],
      type: ['', [Validators.required]],
      numberOfBeds: ['', [Validators.required, Validators.min(1)]],
      address: [''],
      latitude: [null],
      longitude: [null],
      irradiationClass: [''], // Déterminé automatiquement depuis la DB
      installableSurfaceM2: [''],
      monthlyConsumptionKwh: ['']
    });
  }

  ngOnInit(): void {
    // Vérifier si on est en mode édition
    this.route.queryParams.subscribe(params => {
      if (params['id']) {
        this.isEditMode = true;
        this.establishmentId = parseInt(params['id']);
        
        // Pré-remplir avec les données passées en paramètres (fallback)
        if (params['name'] || params['type'] || params['numberOfBeds']) {
          this.establishmentForm.patchValue({
            name: params['name'] || '',
            type: params['type'] || '',
            numberOfBeds: params['numberOfBeds'] || '',
            address: params['address'] || '',
            irradiationClass: params['irradiationClass'] || ''
          });
          
          // Si on a des coordonnées, préparer la carte
          if (params['latitude'] && params['longitude']) {
            const lat = parseFloat(params['latitude']);
            const lng = parseFloat(params['longitude']);
            
            if (!isNaN(lat) && !isNaN(lng)) {
              this.selectedLocation = L.latLng(lat, lng);
              this.addressFromMap = params['address'] || '';
              
              if (params['irradiationClass']) {
                this.irradiationData = {
                  irradiationClass: params['irradiationClass'],
                  latitude: lat,
                  longitude: lng
                } as IrradiationResponse;
                
                // Mettre à jour le formulaire avec la zone
                this.establishmentForm.patchValue({
                  irradiationClass: params['irradiationClass']
                });
                
                // Essayer de mettre à jour la carte si elle est déjà prête
                setTimeout(() => {
                  if (this.map) {
                    this.updateMapWithLocation(lat, lng, params['irradiationClass']);
                  }
                }, 500);
              }
              
              // Centrer la carte
              this.mapOptions.center = L.latLng(lat, lng);
              this.mapOptions.zoom = 12;
            }
          }
        }
        
        // Essayer de charger les données complètes depuis le backend
        this.loadEstablishmentForEdit(this.establishmentId);
      } else {
        // Mode création - essayer d'obtenir la position actuelle de l'utilisateur
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              const lat = position.coords.latitude;
              const lng = position.coords.longitude;
              
              // Vérifier si on est au Maroc (approximativement)
              if (lat >= 20 && lat <= 36 && lng >= -17 && lng <= -1) {
                this.mapOptions.center = L.latLng(lat, lng);
                this.mapOptions.zoom = 12;
                if (this.map) {
                  this.map.setView([lat, lng], 12);
                }
              }
            },
            () => {
              // En cas d'erreur, utiliser Casablanca par défaut
              this.mapOptions.center = L.latLng(33.5731, -7.5898);
              this.mapOptions.zoom = 12;
            }
          );
        }
      }
    });
  }

  loadEstablishmentForEdit(id: number): void {
    this.isLoading = true;
    this.errorMessage = ''; // Réinitialiser l'erreur
    
    this.establishmentService.getEstablishment(id).subscribe({
      next: (establishment) => {
        // Pré-remplir le formulaire avec les données complètes
        this.establishmentForm.patchValue({
          name: establishment.name || this.establishmentForm.get('name')?.value || '',
          type: establishment.type || this.establishmentForm.get('type')?.value || '',
          numberOfBeds: establishment['numberOfBeds'] || this.establishmentForm.get('numberOfBeds')?.value || '',
          address: establishment['address'] || this.establishmentForm.get('address')?.value || '',
          irradiationClass: establishment['irradiationClass'] || this.establishmentForm.get('irradiationClass')?.value || '',
          installableSurfaceM2: establishment['installableSurfaceM2'] || '',
          monthlyConsumptionKwh: establishment['monthlyConsumptionKwh'] || ''
        });

        // Mettre à jour l'adresse si disponible
        if (establishment['address']) {
          this.addressFromMap = establishment['address'];
          // Mettre à jour aussi le formulaire
          this.establishmentForm.patchValue({
            address: establishment['address']
          });
        }

        // Si on a des coordonnées, charger la position sur la carte
        if (establishment['latitude'] && establishment['longitude']) {
          const lat = parseFloat(establishment['latitude']);
          const lng = parseFloat(establishment['longitude']);
          
          this.selectedLocation = L.latLng(lat, lng);
          
          // Charger la zone d'irradiation
          this.locationService.getIrradiationClass(lat, lng).subscribe({
            next: (response) => {
              this.irradiationData = response;
              this.updateMapWithLocation(lat, lng, response.irradiationClass);
              this.isLoading = false;
            },
            error: () => {
              // Si erreur, utiliser la zone déjà enregistrée
              if (establishment['irradiationClass']) {
                this.irradiationData = {
                  irradiationClass: establishment['irradiationClass'],
                  latitude: lat,
                  longitude: lng
                } as IrradiationResponse;
                this.updateMapWithLocation(lat, lng, establishment['irradiationClass']);
              }
              this.isLoading = false;
            }
          });
        } else if (this.selectedLocation) {
          // Si on a déjà une position depuis les queryParams, utiliser celle-ci
          const lat = this.selectedLocation.lat;
          const lng = this.selectedLocation.lng;
          
          if (this.irradiationData) {
            this.updateMapWithLocation(lat, lng, this.irradiationData.irradiationClass);
          }
          this.isLoading = false;
        } else {
          this.isLoading = false;
        }
      },
      error: (error) => {
        console.error('Error loading establishment:', error);
        
        // Afficher un message d'erreur mais permettre quand même l'édition
        if (error.status === 404) {
          this.errorMessage = 'Établissement non trouvé. Vous pouvez quand même modifier les informations affichées.';
        } else if (error.status === 401) {
          this.errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          setTimeout(() => {
            this.router.navigate(['/login']);
          }, 2000);
        } else if (error.status === 0) {
          this.errorMessage = 'Impossible de charger les données complètes depuis le serveur. Les informations de base sont affichées, vous pouvez les modifier.';
        } else {
          this.errorMessage = 'Erreur lors du chargement des données complètes. Les informations de base sont affichées, vous pouvez les modifier.';
        }
        
        // Permettre quand même l'édition avec les données de base
        this.isLoading = false;
      }
    });
  }

  updateMapWithLocation(lat: number, lng: number, zoneClass: string): void {
    // Attendre que la carte soit prête
    if (!this.map) {
      setTimeout(() => this.updateMapWithLocation(lat, lng, zoneClass), 100);
      return;
    }

    // Supprimer les anciens éléments
    if (this.marker && this.map) {
      this.map.removeLayer(this.marker);
    }
    if (this.zoneCircle && this.map) {
      this.map.removeLayer(this.zoneCircle);
    }

    // Définir les couleurs et rayons selon la zone
    const zoneConfig: { [key: string]: { color: string, radius: number } } = {
      'A': { color: '#FF6B35', radius: 50000 },
      'B': { color: '#FFA726', radius: 40000 },
      'C': { color: '#FFD54F', radius: 30000 },
      'D': { color: '#90CAF9', radius: 25000 }
    };

    const config = zoneConfig[zoneClass] || zoneConfig['C'];

    // Ajouter le cercle de zone
    this.zoneCircle = L.circle([lat, lng], {
      radius: config.radius,
      color: config.color,
      fillColor: config.color,
      fillOpacity: 0.2,
      weight: 3,
      opacity: 0.6
    }).addTo(this.map);

    // Ajouter le marqueur
    this.marker = L.marker([lat, lng], {
      icon: createCustomIcon(zoneClass)
    }).addTo(this.map);

    // Ajuster la vue
    const bounds = this.zoneCircle.getBounds();
    this.map.fitBounds(bounds, { padding: [50, 50] });
  }

  ngAfterViewInit(): void {
    // La carte sera initialisée via leafletMapReady
  }

  onMapReady(map: L.Map): void {
    this.map = map;
    
    // Ajouter un gestionnaire de clic sur la carte
    map.on('click', (e: L.LeafletMouseEvent) => {
      this.onMapClick(e.latlng);
    });

    // Si on est en mode édition et qu'on a déjà une position chargée, mettre à jour la carte
    if (this.isEditMode && this.selectedLocation && this.irradiationData) {
      this.updateMapWithLocation(
        this.selectedLocation.lat,
        this.selectedLocation.lng,
        this.irradiationData.irradiationClass
      );
    }
  }

  onMapClick(latlng: L.LatLng): void {
    this.selectedLocation = latlng;
    this.isLoadingLocation = true;
    this.errorMessage = '';
    
    // Supprimer l'ancien marqueur et cercle de zone
    if (this.marker && this.map) {
      this.map.removeLayer(this.marker);
    }
    if (this.zoneCircle && this.map) {
      this.map.removeLayer(this.zoneCircle);
    }
    
    // Appeler le service pour obtenir la zone d'irradiation
    this.locationService.getIrradiationClass(latlng.lat, latlng.lng).subscribe({
      next: (response) => {
        this.irradiationData = response;
        
        // Définir les couleurs et rayons selon la zone
        const zoneConfig: { [key: string]: { color: string, radius: number } } = {
          'A': { color: '#FF6B35', radius: 50000 }, // 50km pour Zone A
          'B': { color: '#FFA726', radius: 40000 }, // 40km pour Zone B
          'C': { color: '#FFD54F', radius: 30000 }, // 30km pour Zone C
          'D': { color: '#90CAF9', radius: 25000 }  // 25km pour Zone D
        };
        
        const config = zoneConfig[response.irradiationClass] || zoneConfig['C'];
        
        // Ajouter un cercle coloré pour représenter la zone
        if (this.map) {
          this.zoneCircle = L.circle([latlng.lat, latlng.lng], {
            radius: config.radius,
            color: config.color,
            fillColor: config.color,
            fillOpacity: 0.2,
            weight: 3,
            opacity: 0.6
          }).addTo(this.map);
          
          // Ajouter un marqueur personnalisé avec la couleur de la zone
          this.marker = L.marker([latlng.lat, latlng.lng], {
            icon: createCustomIcon(response.irradiationClass)
          }).addTo(this.map);
          
          // Ajuster la vue pour voir la zone complète
          const bounds = this.zoneCircle.getBounds();
          this.map.fitBounds(bounds, { padding: [50, 50] });
        }
        
        // Mettre à jour le formulaire avec la zone d'irradiation
        this.establishmentForm.patchValue({
          irradiationClass: response.irradiationClass,
          latitude: response.latitude,
          longitude: response.longitude,
          address: response.nearestCity 
            ? `${response.nearestCity.name}, ${response.nearestCity.region}, Maroc`
            : `${latlng.lat.toFixed(4)}, ${latlng.lng.toFixed(4)}`
        });
        
        this.addressFromMap = response.nearestCity 
          ? `${response.nearestCity.name}, ${response.nearestCity.region}, Maroc`
          : `${latlng.lat.toFixed(4)}, ${latlng.lng.toFixed(4)}`;
        
        this.isLoadingLocation = false;
      },
      error: (error) => {
        console.error('Error getting irradiation class:', error);
        this.errorMessage = 'Erreur lors de la détermination de la zone d\'irradiation. Veuillez réessayer.';
        this.isLoadingLocation = false;
      }
    });
  }

  onSubmit(): void {
    if (this.establishmentForm.valid && (this.selectedLocation || this.isEditMode)) {
      this.isLoading = true;
      this.errorMessage = '';
      
      const formValue = this.establishmentForm.value;
      const establishmentData: any = {
        name: formValue.name,
        type: formValue.type,
        numberOfBeds: parseInt(formValue.numberOfBeds),
        address: formValue.address || this.addressFromMap || null,
        irradiationClass: formValue.irradiationClass || (this.irradiationData?.irradiationClass),
        installableSurfaceM2: formValue.installableSurfaceM2 ? parseFloat(formValue.installableSurfaceM2) : null,
        monthlyConsumptionKwh: formValue.monthlyConsumptionKwh ? parseFloat(formValue.monthlyConsumptionKwh) : null
      };

      // Ajouter les coordonnées si disponibles
      if (this.selectedLocation) {
        establishmentData.latitude = this.selectedLocation.lat;
        establishmentData.longitude = this.selectedLocation.lng;
      } else if (this.isEditMode && this.irradiationData) {
        establishmentData.latitude = this.irradiationData.latitude;
        establishmentData.longitude = this.irradiationData.longitude;
      }
      
      if (this.isEditMode && this.establishmentId) {
        // Mode édition
        this.establishmentService.updateEstablishment(this.establishmentId, establishmentData).subscribe({
          next: (establishment) => {
            this.router.navigate(['/establishments'], { 
              queryParams: { updated: 'true' } 
            });
          },
          error: (error) => {
            console.error('Error updating establishment:', error);
            if (error.status === 400) {
              this.errorMessage = error.error?.message || 'Données invalides. Veuillez vérifier les informations saisies.';
            } else if (error.status === 401) {
              this.errorMessage = 'Session expirée. Veuillez vous reconnecter.';
              setTimeout(() => {
                this.router.navigate(['/login']);
              }, 2000);
            } else if (error.status === 0) {
              this.errorMessage = 'Impossible de contacter le serveur. Vérifiez que le backend est démarré sur http://localhost:8080';
            } else {
              this.errorMessage = error.error?.message || 'Erreur lors de la modification de l\'établissement. Veuillez réessayer.';
            }
            this.isLoading = false;
          }
        });
      } else {
        // Mode création
        this.establishmentService.createEstablishment(establishmentData).subscribe({
          next: (establishment) => {
            // Workflow normal : après création, aller vers les résultats complets
            this.router.navigate(['/mobile/results/comprehensive'], { 
              queryParams: { establishmentId: establishment.id } 
            });
          },
          error: (error) => {
            console.error('Error creating establishment:', error);
            if (error.status === 400) {
              this.errorMessage = error.error?.message || 'Données invalides. Veuillez vérifier les informations saisies.';
            } else if (error.status === 401) {
              this.errorMessage = 'Session expirée. Veuillez vous reconnecter.';
              setTimeout(() => {
                this.router.navigate(['/login']);
              }, 2000);
            } else if (error.status === 0) {
              this.errorMessage = 'Impossible de contacter le serveur. Vérifiez que le backend est démarré sur http://localhost:8080';
            } else {
              this.errorMessage = error.error?.message || 'Erreur lors de la création de l\'établissement. Veuillez réessayer.';
            }
            this.isLoading = false;
          }
        });
      }
    }
  }

  cancel(): void {
    if (this.isEditMode) {
      this.router.navigate(['/establishments']);
    } else {
      this.router.navigate(['/dashboard']);
    }
  }
}

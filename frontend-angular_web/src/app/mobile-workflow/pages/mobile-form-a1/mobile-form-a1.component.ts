import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { LocationService, IrradiationResponse } from '../../../services/location.service';
import { MobileDraftService } from '../../services/mobile-draft.service';
import { EstablishmentService } from '../../../services/establishment.service';

@Component({
  selector: 'app-mobile-form-a1',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Identification de l'établissement</div>
          <div class="mw-sub">Étape 1/3</div>
        </div>
      </div>

      <div class="mw-content">
        <app-form-progress [currentStep]="1" [totalSteps]="3" [labels]="['Identification','Technique','Équipements']"></app-form-progress>

        <form class="mw-card" [formGroup]="form">
          <h2>Informations de base</h2>

          <div class="mw-row">
            <div class="mw-field">
              <label>Type d'établissement *</label>
              <app-hierarchical-type-selector
                [value]="form.get('type')?.value"
                (valueChange)="onTypeChange($event)"
              ></app-hierarchical-type-selector>
              <div class="mw-error" *ngIf="form.get('type')?.touched && form.get('type')?.hasError('required')">
                Veuillez sélectionner un type
              </div>
            </div>
          </div>

          <div class="mw-row">
            <div class="mw-field">
              <label>Nom de l'établissement *</label>
              <input type="text" formControlName="name" placeholder="Ex: Hôpital Ibn Sina" />
              <div class="mw-error" *ngIf="form.get('name')?.touched && form.get('name')?.hasError('required')">
                Le nom est requis
              </div>
            </div>
          </div>

          <div class="mw-row">
            <div class="mw-field">
              <label>Nombre de lits *</label>
              <input type="number" formControlName="numberOfBeds" min="1" placeholder="Ex: 150" />
              <div class="mw-error" *ngIf="form.get('numberOfBeds')?.touched && form.get('numberOfBeds')?.hasError('required')">
                Le nombre de lits est requis
              </div>
            </div>
          </div>
        </form>

        <div class="mw-card">
          <h2>Localisation</h2>
          <p class="mw-muted">Choisie via Map Selection (EXISTANT).</p>

          <div class="mw-location" *ngIf="lat != null && lng != null">
            <div class="mw-loc-line">
              <strong>Coordonnées:</strong> Lat: {{ lat.toFixed(6) }}, Lng: {{ lng.toFixed(6) }}
            </div>
            <div class="mw-loc-line" *ngIf="irradiation">
              <strong>Zone:</strong> {{ locationService.getZoneLabel(irradiation.irradiationClass) }}
              <span *ngIf="irradiation.nearestCity"> — {{ irradiation.nearestCity.name }}, {{ irradiation.nearestCity.region }}</span>
            </div>
          </div>

          <div class="mw-actions">
            <button class="mw-btn-secondary" (click)="changeLocation()">Modifier</button>
          </div>
        </div>

        <div class="mw-footer">
          <button class="mw-btn" (click)="next()" [disabled]="form.invalid || lat == null || lng == null">
            Continuer
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
        margin-bottom: 12px;
      }
      .mw-row {
        margin-bottom: 14px;
      }
      .mw-field label {
        display: block;
        font-weight: 700;
        font-size: 13px;
        margin-bottom: 8px;
      }
      .mw-field input {
        width: 100%;
        padding: 12px 12px;
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.12);
      }
      .mw-error {
        font-size: 12px;
        color: var(--error);
        margin-top: 6px;
      }
      .mw-muted {
        font-size: 12px;
        opacity: 0.75;
        margin-bottom: 10px;
      }
      .mw-location {
        padding: 12px;
        border-radius: 12px;
        background: rgba(78, 168, 222, 0.06);
        border: 1px solid rgba(78, 168, 222, 0.18);
      }
      .mw-loc-line {
        font-size: 13px;
        margin-bottom: 6px;
      }
      .mw-actions {
        margin-top: 10px;
        display: flex;
        justify-content: flex-end;
      }
      .mw-btn-secondary {
        padding: 10px 14px;
        border-radius: 12px;
        background: #fff;
        border: 1px solid rgba(0, 0, 0, 0.12);
        cursor: pointer;
        font-weight: 700;
      }
      .mw-footer {
        display: flex;
        justify-content: flex-end;
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
      .mw-btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
    `
  ]
})
export class MobileFormA1Component implements OnInit {
  form: FormGroup;
  lat: number | null = null;
  lng: number | null = null;
  irradiation: IrradiationResponse | null = null;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private route: ActivatedRoute,
    public locationService: LocationService,
    private draft: MobileDraftService,
    private establishmentService: EstablishmentService
  ) {
    this.form = this.fb.group({
      type: ['', [Validators.required]],
      name: ['', [Validators.required]],
      numberOfBeds: [null, [Validators.required, Validators.min(1)]]
    });
  }

  ngOnInit(): void {
    // Vérifier si on vient du workflow normal
    this.route.queryParamMap.subscribe(q => {
      const establishmentId = q.get('establishmentId');
      const workflow = q.get('workflow');
      
      // Si on a un establishmentId, charger les données de l'établissement
      if (establishmentId && workflow === 'normal') {
        this.establishmentService.getEstablishment(parseInt(establishmentId)).subscribe({
          next: (est) => {
            // Pré-remplir le formulaire avec les données de l'établissement
            this.form.patchValue({
              type: est.type || '',
              name: est.name || '',
              numberOfBeds: est['numberOfBeds'] || null
            });
            
            // Charger les coordonnées si disponibles
            if (est['latitude'] && est['longitude']) {
              this.lat = parseFloat(est['latitude']);
              this.lng = parseFloat(est['longitude']);
              this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
                next: (res) => (this.irradiation = res),
                error: () => (this.irradiation = null)
              });
            }
          },
          error: (err) => {
            console.error('Error loading establishment:', err);
          }
        });
      } else if (workflow === 'normal' && !establishmentId) {
        // Workflow normal sans establishmentId : charger le premier établissement de l'utilisateur
        this.establishmentService.getUserEstablishments().subscribe({
          next: (establishments) => {
            if (establishments && establishments.length > 0) {
              // Charger le premier établissement
              const firstEst = establishments[0];
              this.form.patchValue({
                type: firstEst.type || '',
                name: firstEst.name || '',
                numberOfBeds: firstEst['numberOfBeds'] || null
              });
              
              // Charger les coordonnées si disponibles
              if (firstEst['latitude'] && firstEst['longitude']) {
                this.lat = parseFloat(firstEst['latitude']);
                this.lng = parseFloat(firstEst['longitude']);
                this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
                  next: (res) => (this.irradiation = res),
                  error: () => (this.irradiation = null)
                });
              }
            }
            // Si pas d'établissement, le formulaire reste vide et l'utilisateur peut créer
          },
          error: (err) => {
            console.error('Error loading establishments:', err);
          }
        });
      }
      
      const lat = q.get('lat');
      const lng = q.get('lng');
      this.lat = lat ? parseFloat(lat) : this.lat;
      this.lng = lng ? parseFloat(lng) : this.lng;

      if (this.lat != null && this.lng != null && !isNaN(this.lat) && !isNaN(this.lng)) {
        this.locationService.getIrradiationClass(this.lat, this.lng).subscribe({
          next: (res) => (this.irradiation = res),
          error: () => (this.irradiation = null)
        });
      }
    });

    const saved = this.draft.get<any>('a1');
    if (saved) {
      this.form.patchValue({
        type: saved.type || '',
        name: saved.name || '',
        numberOfBeds: saved.numberOfBeds ?? null
      });
    }

    this.form.valueChanges.subscribe(v => {
      this.draft.set('a1', v);
    });
  }

  onTypeChange(value: string): void {
    this.form.patchValue({ type: value });
    this.form.get('type')?.markAsTouched();
  }

  changeLocation(): void {
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal') {
      this.router.navigate(['/mobile/map-selection'], { 
        queryParams: { 
          next: '/mobile/a1',
          workflow: 'normal',
          establishmentId: establishmentId || undefined
        } 
      });
    } else {
      this.router.navigate(['/mobile/map-selection'], { queryParams: { next: '/mobile/a1' } });
    }
  }

  next(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid || this.lat == null || this.lng == null) return;
    this.draft.set('a1', { ...this.form.value, lat: this.lat, lng: this.lng, irradiationClass: this.irradiation?.irradiationClass });
    
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal' && establishmentId) {
      this.router.navigate(['/mobile/a2'], { queryParams: { workflow: 'normal', establishmentId } });
    } else {
      this.router.navigate(['/mobile/a2']);
    }
  }

  back(): void {
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    if (workflow === 'normal') {
      this.router.navigate(['/establishments']);
    } else {
      this.router.navigate(['/mobile/choice']);
    }
  }
}


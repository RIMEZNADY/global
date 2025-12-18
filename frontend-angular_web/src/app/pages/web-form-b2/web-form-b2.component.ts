import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { LocationService } from '../../services/location.service';
import { MobileDraftService } from '../../mobile-workflow/services/mobile-draft.service';
import { NavigationComponent } from '../../components/navigation/navigation.component';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';

@Component({
  selector: 'app-web-form-b2',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NavigationComponent, TooltipComponent],
  template: `
    <div class="web-form-container">
      <app-navigation></app-navigation>
      <div class="web-form-content">
        <div class="page-header">
          <h1>Informations du Projet</h1>
          <p>NEW · Étape 2/5 · Définissez les contraintes de votre projet</p>
        </div>

        <div class="form-card">
          <div class="zone-info-card" *ngIf="zoneLabel">
            <div class="zone-header">
              <span class="zone-icon">☀️</span>
              <div>
                <strong>Zone d'irradiation déterminée</strong>
                <p>{{ zoneLabel }}</p>
              </div>
            </div>
            <p class="zone-description">Les valeurs estimées sont basées sur cette zone d'irradiation.</p>
          </div>

          <form [formGroup]="form" class="project-form">
            <div class="form-section">
              <h3>
                Budget global
                <app-tooltip text="Le budget total disponible pour l'installation du microgrid solaire. Vous pouvez spécifier une valeur exacte ou un intervalle (min-max)."></app-tooltip>
              </h3>

              <div class="form-group">
                <div class="form-group-header">
                  <label class="form-label">Budget global (DH)</label>
                  <div class="toggle-container">
                    <span class="toggle-label" [class.active]="!useIntervalBudget">Exact</span>
                    <label class="toggle-switch">
                      <input type="checkbox" [checked]="useIntervalBudget" (change)="toggle('budget', $event)" />
                      <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label" [class.active]="useIntervalBudget">Intervalle</span>
                  </div>
                  <button type="button" class="btn-estimate" (click)="useEstimated('budget')" *ngIf="estimatedBudget">
                    Utiliser estimation
                  </button>
                </div>

                <div class="input-group" *ngIf="!useIntervalBudget">
                  <input type="number" formControlName="budget" placeholder="Ex: 2000000" class="form-input" min="1" />
                  <span class="help-text" *ngIf="estimatedBudget">Estimation suggérée: {{ estimatedBudget | number:'1.0-0' }} DH</span>
                </div>

                <div class="input-group interval" *ngIf="useIntervalBudget">
                  <input type="number" formControlName="budgetMin" placeholder="Minimum" class="form-input" min="1" />
                  <span class="interval-separator">-</span>
                  <input type="number" formControlName="budgetMax" placeholder="Maximum" class="form-input" min="1" />
                </div>

                <div class="error" *ngIf="form.get('budget')?.touched && form.get('budget')?.hasError('required')">
                  Le budget est requis
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>
                Surfaces
                <app-tooltip text="Les surfaces disponibles pour votre établissement. La surface totale correspond à l'ensemble du bâtiment, tandis que la surface solaire est la partie exploitable pour les panneaux photovoltaïques."></app-tooltip>
              </h3>

              <div class="form-group">
                <div class="form-group-header">
                  <label class="form-label">Surface totale (m²)</label>
                  <div class="toggle-container">
                    <span class="toggle-label" [class.active]="!useIntervalTotalSurface">Exact</span>
                    <label class="toggle-switch">
                      <input type="checkbox" [checked]="useIntervalTotalSurface" (change)="toggle('totalSurface', $event)" />
                      <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label" [class.active]="useIntervalTotalSurface">Intervalle</span>
                  </div>
                  <button type="button" class="btn-estimate" (click)="useEstimated('totalSurface')" *ngIf="estimatedSurface">
                    Utiliser estimation
                  </button>
                </div>

                <div class="input-group" *ngIf="!useIntervalTotalSurface">
                  <input type="number" formControlName="totalSurface" placeholder="Ex: 5000" class="form-input" min="1" />
                  <span class="help-text" *ngIf="estimatedSurface">Estimation suggérée: {{ estimatedSurface | number:'1.0-0' }} m²</span>
                </div>

                <div class="input-group interval" *ngIf="useIntervalTotalSurface">
                  <input type="number" formControlName="totalSurfaceMin" placeholder="Minimum" class="form-input" min="1" />
                  <span class="interval-separator">-</span>
                  <input type="number" formControlName="totalSurfaceMax" placeholder="Maximum" class="form-input" min="1" />
                </div>
              </div>

              <div class="form-group">
                <div class="form-group-header">
                  <label class="form-label">Surface exploitable pour panneaux (m²)</label>
                  <div class="toggle-container">
                    <span class="toggle-label" [class.active]="!useIntervalSolarSurface">Exact</span>
                    <label class="toggle-switch">
                      <input type="checkbox" [checked]="useIntervalSolarSurface" (change)="toggle('solarSurface', $event)" />
                      <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label" [class.active]="useIntervalSolarSurface">Intervalle</span>
                  </div>
                </div>

                <div class="input-group" *ngIf="!useIntervalSolarSurface">
                  <input type="number" formControlName="solarSurface" placeholder="Ex: 2000" class="form-input" min="0" />
                </div>

                <div class="input-group interval" *ngIf="useIntervalSolarSurface">
                  <input type="number" formControlName="solarSurfaceMin" placeholder="Minimum" class="form-input" min="0" />
                  <span class="interval-separator">-</span>
                  <input type="number" formControlName="solarSurfaceMax" placeholder="Maximum" class="form-input" min="0" />
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>
                Population
                <app-tooltip text="La population environnante que votre établissement servira. Cette valeur peut être estimée automatiquement depuis la localisation GPS."></app-tooltip>
              </h3>

              <div class="form-group">
                <div class="form-group-header">
                  <label class="form-label">Population environnante</label>
                  <div class="toggle-container">
                    <span class="toggle-label" [class.active]="!useIntervalPopulation">Exact</span>
                    <label class="toggle-switch">
                      <input type="checkbox" [checked]="useIntervalPopulation" (change)="toggle('population', $event)" />
                      <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label" [class.active]="useIntervalPopulation">Intervalle</span>
                  </div>
                  <button type="button" class="btn-estimate" (click)="useEstimated('population')" [disabled]="isEstimatingPop">
                    {{ isEstimatingPop ? 'Estimation...' : 'Estimer' }}
                  </button>
                </div>

                <div class="input-group" *ngIf="!useIntervalPopulation">
                  <input type="number" formControlName="population" placeholder="Ex: 50000" class="form-input" min="1" />
                  <span class="help-text" *ngIf="estimatedPopulation">Estimation: {{ estimatedPopulation | number:'1.0-0' }} habitants</span>
                </div>

                <div class="input-group interval" *ngIf="useIntervalPopulation">
                  <input type="number" formControlName="populationMin" placeholder="Minimum" class="form-input" min="1" />
                  <span class="interval-separator">-</span>
                  <input type="number" formControlName="populationMax" placeholder="Maximum" class="form-input" min="1" />
                </div>
              </div>
            </div>

            <div class="error-message" *ngIf="errorMessage">
              <span>{{ errorMessage }}</span>
            </div>

            <div class="form-actions">
              <button type="button" class="btn-secondary" (click)="back()">Retour</button>
              <button type="button" class="btn-primary" (click)="next()" [disabled]="form.invalid">
                Continuer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./web-form-b2.component.scss']
})
export class WebFormB2Component implements OnInit {
  form: FormGroup;
  useIntervalBudget = false;
  useIntervalTotalSurface = false;
  useIntervalSolarSurface = false;
  useIntervalPopulation = false;

  estimatedBudget: number | null = null;
  estimatedSurface: number | null = null;
  estimatedPopulation: number | null = null;
  isEstimatingPop = false;
  errorMessage = '';
  zoneLabel: string | null = null;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private locationService: LocationService,
    private draft: MobileDraftService
  ) {
    this.form = this.fb.group({
      budget: [null, [Validators.required, Validators.min(1)]],
      budgetMin: [null],
      budgetMax: [null],
      totalSurface: [null, [Validators.required, Validators.min(1)]],
      totalSurfaceMin: [null],
      totalSurfaceMax: [null],
      solarSurface: [null, [Validators.required, Validators.min(0)]],
      solarSurfaceMin: [null],
      solarSurfaceMax: [null],
      population: [null, [Validators.required, Validators.min(1)]],
      populationMin: [null],
      populationMax: [null]
    });
  }

  ngOnInit(): void {
    const b1 = this.draft.get<any>('b1');
    if (b1?.irradiationClass) this.zoneLabel = this.locationService.getZoneLabel(b1.irradiationClass);

    this.estimateValues();
    this.estimatePopulation();

    const saved = this.draft.get<any>('b2');
    if (saved) {
      this.useIntervalBudget = !!saved.useIntervalBudget;
      this.useIntervalTotalSurface = !!saved.useIntervalTotalSurface;
      this.useIntervalSolarSurface = !!saved.useIntervalSolarSurface;
      this.useIntervalPopulation = !!saved.useIntervalPopulation;
      this.form.patchValue(saved);
    }
    this.applyValidators();

    this.form.valueChanges.subscribe(v => {
      this.draft.set('b2', {
        ...v,
        useIntervalBudget: this.useIntervalBudget,
        useIntervalTotalSurface: this.useIntervalTotalSurface,
        useIntervalSolarSurface: this.useIntervalSolarSurface,
        useIntervalPopulation: this.useIntervalPopulation
      });
    });
  }

  private applyValidators(): void {
    if (this.useIntervalBudget) {
      this.form.get('budget')?.clearValidators();
      this.form.get('budgetMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('budgetMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('budget')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('budgetMin')?.clearValidators();
      this.form.get('budgetMax')?.clearValidators();
    }

    if (this.useIntervalTotalSurface) {
      this.form.get('totalSurface')?.clearValidators();
      this.form.get('totalSurfaceMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('totalSurfaceMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('totalSurface')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('totalSurfaceMin')?.clearValidators();
      this.form.get('totalSurfaceMax')?.clearValidators();
    }

    if (this.useIntervalSolarSurface) {
      this.form.get('solarSurface')?.clearValidators();
      this.form.get('solarSurfaceMin')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMax')?.setValidators([Validators.required, Validators.min(0)]);
    } else {
      this.form.get('solarSurface')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMin')?.clearValidators();
      this.form.get('solarSurfaceMax')?.clearValidators();
    }

    if (this.useIntervalPopulation) {
      this.form.get('population')?.clearValidators();
      this.form.get('populationMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('populationMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('population')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('populationMin')?.clearValidators();
      this.form.get('populationMax')?.clearValidators();
    }

    Object.keys(this.form.controls).forEach(k => this.form.get(k)?.updateValueAndValidity({ emitEvent: false }));
  }

  toggle(kind: 'budget'|'totalSurface'|'solarSurface'|'population', e: Event): void {
    const v = (e.target as HTMLInputElement).checked;
    if (kind === 'budget') this.useIntervalBudget = v;
    if (kind === 'totalSurface') this.useIntervalTotalSurface = v;
    if (kind === 'solarSurface') this.useIntervalSolarSurface = v;
    if (kind === 'population') this.useIntervalPopulation = v;
    this.applyValidators();
  }

  private estimateValues(): void {
    const b1 = this.draft.get<any>('b1');
    const zone = b1?.irradiationClass as ('A'|'B'|'C'|'D'|null);
    const mult = zone === 'A' ? 1.2 : zone === 'B' ? 1.1 : zone === 'C' ? 1.0 : 0.9;
    this.estimatedBudget = Math.round(2000000 * mult);
    this.estimatedSurface = Math.round(5000 * mult);
  }

  estimatePopulation(): void {
    const b1 = this.draft.get<any>('b1');
    if (!b1?.lat || !b1?.lng) return;
    this.isEstimatingPop = true;
    this.locationService.estimatePopulation({ latitude: b1.lat, longitude: b1.lng }).subscribe({
      next: (n) => {
        this.estimatedPopulation = n;
        this.isEstimatingPop = false;
        if (!this.useIntervalPopulation && !this.form.value.population) {
          this.form.patchValue({ population: n }, { emitEvent: true });
        }
      },
      error: () => {
        this.isEstimatingPop = false;
        this.estimatedPopulation = null;
      }
    });
  }

  useEstimated(which: 'budget'|'totalSurface'|'population'): void {
    if (which === 'budget' && this.estimatedBudget != null) {
      this.form.patchValue({ budget: this.estimatedBudget });
    }
    if (which === 'totalSurface' && this.estimatedSurface != null) {
      this.form.patchValue({ totalSurface: this.estimatedSurface });
    }
    if (which === 'population') {
      if (this.estimatedPopulation != null) {
        if (this.useIntervalPopulation) {
          const min = Math.round(this.estimatedPopulation * 0.8);
          const max = Math.round(this.estimatedPopulation * 1.2);
          this.form.patchValue({ populationMin: min, populationMax: max });
        } else {
          this.form.patchValue({ population: this.estimatedPopulation });
        }
      } else {
        this.estimatePopulation();
      }
    }
  }

  private avg(min: number | null, max: number | null): number | null {
    if (min == null || max == null || min >= max) return null;
    return (min + max) / 2;
  }

  private getValue(useInterval: boolean, exact: number | null, min: number | null, max: number | null): number | null {
    if (!useInterval) return exact;
    return this.avg(min, max);
  }

  next(): void {
    this.errorMessage = '';
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const budget = this.getValue(this.useIntervalBudget, this.form.value.budget, this.form.value.budgetMin, this.form.value.budgetMax);
    const totalSurface = this.getValue(this.useIntervalTotalSurface, this.form.value.totalSurface, this.form.value.totalSurfaceMin, this.form.value.totalSurfaceMax);
    const solarSurface = this.getValue(this.useIntervalSolarSurface, this.form.value.solarSurface, this.form.value.solarSurfaceMin, this.form.value.solarSurfaceMax);
    const population = this.getValue(this.useIntervalPopulation, this.form.value.population, this.form.value.populationMin, this.form.value.populationMax);
    
    if (budget == null || totalSurface == null || solarSurface == null || population == null) {
      this.errorMessage = 'Veuillez vérifier les intervalles (min < max) et les valeurs.';
      return;
    }

    this.draft.set('b2_calc', { budget, totalSurface, solarSurface, population: Math.round(population) });
    this.router.navigate(['/web/b3']);
  }

  back(): void {
    this.router.navigate(['/web/b1']);
  }
}

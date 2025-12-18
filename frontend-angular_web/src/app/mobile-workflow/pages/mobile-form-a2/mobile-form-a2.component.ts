import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { MobileDraftService } from '../../services/mobile-draft.service';

@Component({
  selector: 'app-mobile-form-a2',
  template: `
    <div class="mw-page">
      <div class="mw-topbar">
        <button class="mw-back" (click)="back()">←</button>
        <div>
          <div class="mw-title">Informations techniques</div>
          <div class="mw-sub">Étape 2/3</div>
        </div>
      </div>

      <div class="mw-content">
        <app-form-progress [currentStep]="2" [totalSteps]="3" [labels]="['Identification','Technique','Équipements']"></app-form-progress>

        <form class="mw-card" [formGroup]="form">
          <h2>Surfaces & Consommation</h2>

          <div class="mw-alert" *ngIf="contextualAlert">{{ contextualAlert }}</div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Surface installable pour panneau solaire (m²)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalSolar" (change)="toggleSolar($event)" />
                <span>Intervalle</span>
              </div>
            </div>
            <div class="mw-grid" *ngIf="!useIntervalSolar">
              <input type="number" formControlName="solarSurface" placeholder="Ex: 500" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalSolar">
              <input type="number" formControlName="solarSurfaceMin" placeholder="Min" />
              <input type="number" formControlName="solarSurfaceMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Surface non critique disponible (m²)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalNonCritical" (change)="toggleNonCritical($event)" />
                <span>Intervalle</span>
              </div>
            </div>
            <div class="mw-grid" *ngIf="!useIntervalNonCritical">
              <input type="number" formControlName="nonCriticalSurface" placeholder="Ex: 200" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalNonCritical">
              <input type="number" formControlName="nonCriticalSurfaceMin" placeholder="Min" />
              <input type="number" formControlName="nonCriticalSurfaceMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-block">
            <div class="mw-block-head">
              <label>Consommation mensuelle actuelle (kWh)</label>
              <div class="mw-toggle">
                <span>Exact</span>
                <input type="checkbox" [checked]="useIntervalConsumption" (change)="toggleConsumption($event)" />
                <span>Intervalle</span>
              </div>
            </div>
            <div class="mw-grid" *ngIf="!useIntervalConsumption">
              <input type="number" formControlName="monthlyConsumption" placeholder="Ex: 50000" />
            </div>
            <div class="mw-grid2" *ngIf="useIntervalConsumption">
              <input type="number" formControlName="monthlyConsumptionMin" placeholder="Min" />
              <input type="number" formControlName="monthlyConsumptionMax" placeholder="Max" />
            </div>
          </div>

          <div class="mw-footer">
            <button type="button" class="mw-btn" (click)="next()" [disabled]="form.invalid">
              Continuer
            </button>
          </div>
        </form>
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
      .mw-alert {
        margin-bottom: 14px;
        padding: 12px;
        border-radius: 12px;
        background: rgba(107, 207, 157, 0.12);
        border: 1px solid rgba(107, 207, 157, 0.35);
        font-size: 13px;
      }
      .mw-block {
        padding: 12px;
        border-radius: 14px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        margin-bottom: 12px;
      }
      .mw-block-head {
        display: flex;
        justify-content: space-between;
        gap: 12px;
        align-items: center;
        margin-bottom: 10px;
      }
      .mw-block label {
        font-weight: 800;
        font-size: 13px;
      }
      .mw-toggle {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 12px;
        opacity: 0.8;
      }
      .mw-grid input,
      .mw-grid2 input {
        width: 100%;
        padding: 12px 12px;
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.12);
      }
      .mw-grid2 {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
      }
      .mw-footer {
        display: flex;
        justify-content: flex-end;
        margin-top: 10px;
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
export class MobileFormA2Component implements OnInit {
  form: FormGroup;
  useIntervalSolar = false;
  useIntervalNonCritical = false;
  useIntervalConsumption = false;
  contextualAlert: string | null = null;

  constructor(
    private fb: FormBuilder, 
    private router: Router, 
    private route: ActivatedRoute,
    private draft: MobileDraftService
  ) {
    this.form = this.fb.group({
      solarSurface: [null, [Validators.required, Validators.min(0)]],
      solarSurfaceMin: [null],
      solarSurfaceMax: [null],
      nonCriticalSurface: [null, [Validators.required, Validators.min(0)]],
      nonCriticalSurfaceMin: [null],
      nonCriticalSurfaceMax: [null],
      monthlyConsumption: [null, [Validators.required, Validators.min(1)]],
      monthlyConsumptionMin: [null],
      monthlyConsumptionMax: [null]
    });
  }

  ngOnInit(): void {
    const saved = this.draft.get<any>('a2');
    if (saved) {
      this.useIntervalSolar = !!saved.useIntervalSolar;
      this.useIntervalNonCritical = !!saved.useIntervalNonCritical;
      this.useIntervalConsumption = !!saved.useIntervalConsumption;
      this.form.patchValue(saved);
    }
    this.applyValidators();
    this.form.valueChanges.subscribe(v => {
      this.draft.set('a2', {
        ...v,
        useIntervalSolar: this.useIntervalSolar,
        useIntervalNonCritical: this.useIntervalNonCritical,
        useIntervalConsumption: this.useIntervalConsumption
      });
      this.computeContextAlert();
    });
    this.computeContextAlert();
  }

  private applyValidators(): void {
    // Solar
    if (this.useIntervalSolar) {
      this.form.get('solarSurface')?.clearValidators();
      this.form.get('solarSurfaceMin')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMax')?.setValidators([Validators.required, Validators.min(0)]);
    } else {
      this.form.get('solarSurface')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('solarSurfaceMin')?.clearValidators();
      this.form.get('solarSurfaceMax')?.clearValidators();
    }
    // Non critical
    if (this.useIntervalNonCritical) {
      this.form.get('nonCriticalSurface')?.clearValidators();
      this.form.get('nonCriticalSurfaceMin')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('nonCriticalSurfaceMax')?.setValidators([Validators.required, Validators.min(0)]);
    } else {
      this.form.get('nonCriticalSurface')?.setValidators([Validators.required, Validators.min(0)]);
      this.form.get('nonCriticalSurfaceMin')?.clearValidators();
      this.form.get('nonCriticalSurfaceMax')?.clearValidators();
    }
    // Consumption
    if (this.useIntervalConsumption) {
      this.form.get('monthlyConsumption')?.clearValidators();
      this.form.get('monthlyConsumptionMin')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('monthlyConsumptionMax')?.setValidators([Validators.required, Validators.min(1)]);
    } else {
      this.form.get('monthlyConsumption')?.setValidators([Validators.required, Validators.min(1)]);
      this.form.get('monthlyConsumptionMin')?.clearValidators();
      this.form.get('monthlyConsumptionMax')?.clearValidators();
    }

    Object.keys(this.form.controls).forEach(k => this.form.get(k)?.updateValueAndValidity({ emitEvent: false }));
  }

  private getAvg(min: number | null, max: number | null): number | null {
    if (min == null || max == null) return null;
    if (min >= max) return null;
    return (min + max) / 2;
  }

  private computeContextAlert(): void {
    const solarSurface = this.useIntervalSolar
      ? this.getAvg(this.form.value.solarSurfaceMin, this.form.value.solarSurfaceMax)
      : this.form.value.solarSurface;
    const monthlyConsumption = this.useIntervalConsumption
      ? this.getAvg(this.form.value.monthlyConsumptionMin, this.form.value.monthlyConsumptionMax)
      : this.form.value.monthlyConsumption;

    if (solarSurface == null || monthlyConsumption == null || monthlyConsumption <= 0) {
      this.contextualAlert = null;
      return;
    }

    // Flutter approximation: monthlyProduction = surface * 4.5 * 0.2 * 30
    const monthlyProduction = solarSurface * 4.5 * 0.2 * 30;
    const autonomy = (monthlyProduction / monthlyConsumption) * 100;
    if (autonomy < 50 && solarSurface < 500) {
      this.contextualAlert = `Surface solaire insuffisante: production ≈ ${autonomy.toFixed(
        1
      )}% de la consommation. Pour >50%, une surface ≥ 500 m² est recommandée.`;
    } else if (autonomy > 100) {
      this.contextualAlert = `Excellente configuration: production ≈ ${autonomy.toFixed(
        1
      )}% (excédent possible).`;
    } else if (autonomy >= 50) {
      this.contextualAlert = `Bonne configuration: production ≈ ${autonomy.toFixed(1)}% de la consommation.`;
    } else {
      this.contextualAlert = null;
    }
  }

  toggleSolar(e: Event): void {
    this.useIntervalSolar = (e.target as HTMLInputElement).checked;
    this.applyValidators();
    this.computeContextAlert();
  }
  toggleNonCritical(e: Event): void {
    this.useIntervalNonCritical = (e.target as HTMLInputElement).checked;
    this.applyValidators();
  }
  toggleConsumption(e: Event): void {
    this.useIntervalConsumption = (e.target as HTMLInputElement).checked;
    this.applyValidators();
    this.computeContextAlert();
  }

  private getValue(useInterval: boolean, exact: number | null, min: number | null, max: number | null): number | null {
    if (!useInterval) return exact;
    return this.getAvg(min, max);
  }

  next(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const solarSurface = this.getValue(
      this.useIntervalSolar,
      this.form.value.solarSurface,
      this.form.value.solarSurfaceMin,
      this.form.value.solarSurfaceMax
    );
    const nonCriticalSurface = this.getValue(
      this.useIntervalNonCritical,
      this.form.value.nonCriticalSurface,
      this.form.value.nonCriticalSurfaceMin,
      this.form.value.nonCriticalSurfaceMax
    );
    const monthlyConsumption = this.getValue(
      this.useIntervalConsumption,
      this.form.value.monthlyConsumption,
      this.form.value.monthlyConsumptionMin,
      this.form.value.monthlyConsumptionMax
    );

    if (solarSurface == null || nonCriticalSurface == null || monthlyConsumption == null) return;

    const avgHourlyConsumption = monthlyConsumption / (30 * 24);
    const recommendedPVPower = solarSurface * 0.2;
    const recommendedBatteryCapacity = avgHourlyConsumption * 12;

    this.draft.set('a2_calc', { solarSurface, nonCriticalSurface, monthlyConsumption, recommendedPVPower, recommendedBatteryCapacity });
    
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal' && establishmentId) {
      // Workflow normal : aller vers le formulaire 3 (analyse/graphiques)
      this.router.navigate(['/mobile/a3'], { queryParams: { workflow: 'normal', establishmentId } });
    } else {
      // Workflow mobile : continuer vers A5
      this.router.navigate(['/mobile/a5']);
    }
  }

  back(): void {
    // Vérifier si on vient du workflow normal
    const workflow = this.route.snapshot.queryParamMap.get('workflow');
    const establishmentId = this.route.snapshot.queryParamMap.get('establishmentId');
    
    if (workflow === 'normal' && establishmentId) {
      this.router.navigate(['/mobile/a1'], { queryParams: { workflow: 'normal', establishmentId } });
    } else {
      this.router.navigate(['/mobile/a1']);
    }
  }
}


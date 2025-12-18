import { Component, OnInit, OnDestroy, AfterViewInit, NgZone } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-institution-choice',
  template: `
    <div class="choice-container">
      <div class="choice-card">
        <div class="choice-header">
          <h1 class="gradient-text">Hospital Microgrid</h1>
          <p>Choisissez votre workflow</p>
        </div>

        <div class="choices">
          <button class="choice-btn existing" (click)="goExisting()">
            <span class="icon">🏥</span>
            <span class="label">EXISTANT</span>
            <span class="desc">Sélectionner un établissement existant</span>
          </button>

          <button class="choice-btn new" (click)="goNew()">
            <span class="icon">➕</span>
            <span class="label">NEW</span>
            <span class="desc">Créer un nouvel établissement</span>
          </button>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./institution-choice.component.scss']
})
export class InstitutionChoiceComponent implements OnInit, AfterViewInit, OnDestroy {
  private cleanupInterval?: any;

  constructor(private router: Router, private ngZone: NgZone) {}

  ngOnInit(): void {
    // Nettoyer immédiatement
    this.cleanupModals();
  }

  ngAfterViewInit(): void {
    // Nettoyer après le rendu de la vue
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => this.cleanupModals(), 0);
      setTimeout(() => this.cleanupModals(), 100);
      setTimeout(() => this.cleanupModals(), 300);
    });

    // Nettoyer périodiquement pendant 2 secondes pour capturer les modals créés après
    let attempts = 0;
    this.cleanupInterval = setInterval(() => {
      this.cleanupModals();
      attempts++;
      if (attempts >= 20) { // 2 secondes (20 * 100ms)
        if (this.cleanupInterval) {
          clearInterval(this.cleanupInterval);
        }
      }
    }, 100);
  }

  ngOnDestroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    this.cleanupModals();
  }

  private cleanupModals(): void {
    // Supprimer tous les backdrops et overlays qui pourraient rester
    const backdrops = document.querySelectorAll(
      '.modal-backdrop, .hts-backdrop, [class*="backdrop"], [class*="backdrop-filter"], .modal, [class*="modal"]'
    );
    backdrops.forEach(el => {
      const htmlEl = el as HTMLElement;
      // Vérifier si c'est un backdrop/overlay avant de supprimer
      if (htmlEl.style.position === 'fixed' || 
          htmlEl.classList.contains('modal-backdrop') ||
          htmlEl.classList.contains('hts-backdrop') ||
          htmlEl.style.zIndex === '1040' ||
          htmlEl.style.zIndex === '1050' ||
          htmlEl.style.zIndex === '1060') {
        htmlEl.remove();
      }
    });
    
    // Supprimer les styles de blur du body et html
    document.body.style.filter = '';
    document.body.style.backdropFilter = '';
    document.body.style.pointerEvents = '';
    document.body.style.overflow = '';
    document.body.style.position = '';
    document.body.classList.remove('modal-open');
    
    const html = document.documentElement;
    html.style.filter = '';
    html.style.backdropFilter = '';
    html.style.overflow = '';
    
    // Supprimer les overlays fixes
    const overlays = document.querySelectorAll(
      '.modal-overlay, [class*="overlay"], [class*="modal"]'
    );
    overlays.forEach(el => {
      const overlay = el as HTMLElement;
      const computedStyle = window.getComputedStyle(overlay);
      if (computedStyle.position === 'fixed' && 
          (computedStyle.zIndex === '1040' || 
           computedStyle.zIndex === '1050' || 
           computedStyle.zIndex === '1060' ||
           parseInt(computedStyle.zIndex) > 1000)) {
        overlay.remove();
      }
    });

    // Forcer le réaffichage de la page
    const container = document.querySelector('.choice-container');
    if (container) {
      (container as HTMLElement).style.display = 'flex';
      (container as HTMLElement).style.visibility = 'visible';
      (container as HTMLElement).style.opacity = '1';
      (container as HTMLElement).style.pointerEvents = 'auto';
    }
  }

  goExisting(): void {
    // Workflow normal/web : aller directement vers le premier formulaire (comme mobile)
    // Le formulaire A1 chargera l'établissement s'il y en a un, sinon permettra de le créer
    this.router.navigate(['/mobile/a1'], { queryParams: { workflow: 'normal' } });
  }

  goNew(): void {
    // Workflow NEW : aller vers le premier formulaire du workflow NEW
    this.router.navigate(['/web/b1']);
  }
}



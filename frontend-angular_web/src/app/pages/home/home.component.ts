import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-home',
  template: `
    <div class="home-container">
      <app-navigation></app-navigation>
      <div class="home-content">
        <!-- Hero Section -->
        <section class="hero-section">
          <div class="hero-content">
            <div class="hero-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
              </svg>
            </div>
            <h1 class="hero-title">
              Hospital Microgrid
            </h1>
            <p class="hero-subtitle">
              Optimisez la gestion énergétique de vos établissements de santé avec l'intelligence artificielle
            </p>
            <div class="hero-actions">
              <button class="btn-primary" (click)="goToInstitutionChoice()">
                <span>Commencer</span>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="9 18 15 12 9 6"></polyline>
                </svg>
              </button>
              <button class="btn-secondary" (click)="goToEstablishments()">
                <span>Mes établissements</span>
              </button>
            </div>
          </div>
          <div class="hero-visual">
            <div class="floating-card card-1">
              <div class="card-icon"></div>
              <div class="card-value">2.8 kW</div>
              <div class="card-label">Charge actuelle</div>
            </div>
            <div class="floating-card card-2">
              <div class="card-icon"></div>
              <div class="card-value">1.2 kW</div>
              <div class="card-label">Génération solaire</div>
            </div>
            <div class="floating-card card-3">
              <div class="card-icon"></div>
              <div class="card-value">78%</div>
              <div class="card-label">Batterie</div>
            </div>
          </div>
        </section>

        <!-- Features Section -->
        <section class="features-section">
          <h2 class="section-title">Fonctionnalités principales</h2>
          <div class="features-grid">
            <div class="feature-card" (mouseenter)="onCardHover($event)" (mouseleave)="onCardLeave($event)">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
              </div>
              <h3>Dimensionnement intelligent</h3>
              <p>Calculez automatiquement la taille optimale de votre système de microgrid solaire pour votre établissement</p>
            </div>

            <div class="feature-card" (mouseenter)="onCardHover($event)" (mouseleave)="onCardLeave($event)">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                </svg>
              </div>
              <h3>Prédictions IA</h3>
              <p>Utilisez l'intelligence artificielle pour prédire la consommation énergétique et optimiser votre production solaire</p>
            </div>

            <div class="feature-card" (mouseenter)="onCardHover($event)" (mouseleave)="onCardLeave($event)">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                </svg>
              </div>
              <h3>Auto-apprentissage</h3>
              <p>Le système apprend automatiquement de vos données pour améliorer continuellement ses prédictions</p>
            </div>

            <div class="feature-card" (mouseenter)="onCardHover($event)" (mouseleave)="onCardLeave($event)">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
              </div>
              <h3>Analyse complète</h3>
              <p>Obtenez une analyse détaillée avec 7 onglets couvrant tous les aspects de votre microgrid</p>
            </div>
          </div>
        </section>

        <!-- Benefits Section -->
        <section class="benefits-section">
          <div class="benefits-content">
            <div class="benefits-text">
              <h2>Pourquoi Hospital Microgrid ?</h2>
              <ul class="benefits-list">
                <li>
                  <span class="check-icon">✓</span>
                  <div>
                    <strong>Économies d'énergie</strong>
                    <p>Réduisez vos coûts énergétiques jusqu'à 40%</p>
                  </div>
                </li>
                <li>
                  <span class="check-icon">✓</span>
                  <div>
                    <strong>Durabilité</strong>
                    <p>Contribuez à un avenir plus vert et durable</p>
                  </div>
                </li>
                <li>
                  <span class="check-icon">✓</span>
                  <div>
                    <strong>Fiabilité</strong>
                    <p>Assurez une continuité de service même en cas de panne réseau</p>
                  </div>
                </li>
                <li>
                  <span class="check-icon">✓</span>
                  <div>
                    <strong>Simplicité</strong>
                    <p>Interface intuitive et workflow guidé pour une prise en main rapide</p>
                  </div>
                </li>
              </ul>
            </div>
            <div class="benefits-visual">
              <div class="stats-card">
                <div class="stat-item">
                  <div class="stat-value">40%</div>
                  <div class="stat-label">Économies</div>
                </div>
                <div class="stat-item">
                  <div class="stat-value">24/7</div>
                  <div class="stat-label">Surveillance</div>
                </div>
                <div class="stat-item">
                  <div class="stat-value">100%</div>
                  <div class="stat-label">Renouvelable</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- CTA Section -->
        <section class="cta-section">
          <div class="cta-content">
            <h2>Prêt à optimiser votre microgrid ?</h2>
            <p>Commencez dès maintenant et découvrez le potentiel énergétique de votre établissement</p>
            <button class="btn-cta" (click)="goToInstitutionChoice()">
              <span>Démarrer maintenant</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>
        </section>
      </div>
    </div>
  `,
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  constructor(private router: Router) {}

  ngOnInit(): void {
    // Animation triggers on init
  }

  goToInstitutionChoice(): void {
    this.router.navigate(['/institution-choice']);
  }

  goToEstablishments(): void {
    this.router.navigate(['/establishments']);
  }

  onCardHover(event: MouseEvent): void {
    const card = event.currentTarget as HTMLElement;
    card.style.transform = 'translateY(-8px) scale(1.02)';
  }

  onCardLeave(event: MouseEvent): void {
    const card = event.currentTarget as HTMLElement;
    card.style.transform = 'translateY(0) scale(1)';
  }
}


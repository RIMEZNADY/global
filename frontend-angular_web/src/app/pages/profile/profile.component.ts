import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule, NavigationEnd } from '@angular/router';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators, FormsModule } from '@angular/forms';
import { ApiService } from '../../services/api.service';
import { AuthService } from '../../services/auth.service';
import { TooltipComponent } from '../../components/tooltip/tooltip.component';
import { Subscription, filter } from 'rxjs';

interface UserProfile {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  role: string;
  active: boolean;
  createdAt: string;
  establishments: Array<{
    id: number;
    name: string;
    type: string;
    status: string;
    createdAt: string;
  }>;
}

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule, FormsModule, TooltipComponent],
  template: `
    <div class="dashboard-layout">
      <!-- Left Sidebar -->
      <aside class="dashboard-sidebar">
        <div class="sidebar-header">
          <div class="sidebar-logo">
            <div class="logo-icon">⚡</div>
            <div class="logo-text">
              <div class="logo-title">Hospital</div>
              <div class="logo-subtitle">Microgrid</div>
            </div>
          </div>
        </div>
        <nav class="sidebar-nav">
          <div class="nav-item active">
            <span class="nav-icon">👤</span>
            <span class="nav-label">Profil</span>
          </div>
          <a [routerLink]="['/establishments']" class="nav-item">
            <span class="nav-icon">🏥</span>
            <span class="nav-label">Établissements</span>
          </a>
          <a [routerLink]="['/dashboard']" class="nav-item">
            <span class="nav-icon">📊</span>
            <span class="nav-label">Dashboard</span>
          </a>
        </nav>
      </aside>

      <!-- Main Content Area -->
      <div class="dashboard-main">
        <!-- Top Header -->
        <header class="dashboard-header">
          <div class="header-left">
            <div class="header-title-group">
              <h1 class="header-title">Mon Profil</h1>
              <p class="header-subtitle">Gérez vos informations personnelles</p>
            </div>
          </div>
        </header>

        <!-- Content Area -->
        <main class="dashboard-content">
          <!-- Error Banner (seulement pour erreurs serveur) -->
          <div class="error-banner" *ngIf="errorMessage && !isLoading && errorMessage.includes('serveur')">
            <div class="error-banner-content">
              <span class="error-banner-icon">⚠️</span>
              <span class="error-banner-text">{{ errorMessage }}</span>
              <div class="error-banner-actions">
                <button class="btn-link" (click)="loadProfile()">Réessayer</button>
              </div>
            </div>
          </div>

          <!-- Loading State -->
          <div class="content-loading" *ngIf="isLoading">
            <div class="loading-spinner"></div>
            <p>Chargement du profil...</p>
          </div>

          <!-- Main Content (toujours affiché, même sans données) -->
          <div class="content-grid" *ngIf="profileForm">
            <!-- Profile Image Card -->
            <div class="card card-profile-image">
              <div class="profile-image-container">
                <div class="profile-image-wrapper">
                  <img [src]="getAvatarUrl()" 
                       [alt]="getAvatarAlt()"
                       class="profile-image"
                       (error)="onImageError($event)">
                  <div class="profile-image-overlay" *ngIf="isEditing">
                    <label class="image-upload-btn">
                      <input type="file" 
                             accept="image/*" 
                             (change)="onImageSelected($event)"
                             style="display: none;">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="17 8 12 3 7 8"></polyline>
                        <line x1="12" y1="3" x2="12" y2="15"></line>
                      </svg>
                      <span>Changer</span>
                    </label>
                  </div>
                </div>
                <div class="profile-name">
                  <ng-container *ngIf="userProfile as profile">
                    <h2 *ngIf="profile.firstName && profile.lastName">
                      {{ profile.firstName }} {{ profile.lastName }}
                    </h2>
                    <h2 *ngIf="!profile.firstName || !profile.lastName">
                      {{ profile.email ? (profile.email.split('@')[0]) : 'Chargement...' }}
                    </h2>
                    <p class="profile-email">{{ profile.email || '' }}</p>
                  </ng-container>
                  <ng-container *ngIf="!userProfile && !isLoading">
                    <h2>Chargement...</h2>
                    <p class="profile-email"></p>
                  </ng-container>
                </div>
              </div>
            </div>

            <!-- Profile Form Card -->
            <div class="card card-form">
              <div class="card-header">
                <h2 class="card-title">Informations Personnelles</h2>
                <div class="header-actions" *ngIf="userProfile && profileForm">
                  <button class="btn-secondary" *ngIf="!isEditing" (click)="startEdit()">Modifier</button>
                  <div *ngIf="isEditing">
                    <button class="btn-secondary" (click)="cancelEdit()">Annuler</button>
                    <button class="btn-primary" (click)="saveProfile()" [disabled]="profileForm.invalid || isSaving">
                      <span *ngIf="!isSaving">Enregistrer</span>
                      <span *ngIf="isSaving">Enregistrement...</span>
                    </button>
                  </div>
                </div>
              </div>

              <form [formGroup]="profileForm" *ngIf="profileForm">
                <div class="form-grid">
                  <div class="form-group">
                    <label class="form-label">
                      Prénom
                      <app-tooltip text="Votre prénom tel qu'il apparaîtra dans l'application."></app-tooltip>
                    </label>
                    <input 
                      type="text" 
                      class="form-input" 
                      formControlName="firstName"
                      [readonly]="!isEditing"
                      [class.readonly]="!isEditing">
                    <div class="form-error" *ngIf="profileForm.get('firstName')?.hasError('required') && profileForm.get('firstName')?.touched">
                      Le prénom est requis
                    </div>
                  </div>

                  <div class="form-group">
                    <label class="form-label">
                      Nom
                      <app-tooltip text="Votre nom de famille tel qu'il apparaîtra dans l'application."></app-tooltip>
                    </label>
                    <input 
                      type="text" 
                      class="form-input" 
                      formControlName="lastName"
                      [readonly]="!isEditing"
                      [class.readonly]="!isEditing">
                    <div class="form-error" *ngIf="profileForm.get('lastName')?.hasError('required') && profileForm.get('lastName')?.touched">
                      Le nom est requis
                    </div>
                  </div>

                  <div class="form-group">
                    <label class="form-label">
                      Email
                      <app-tooltip text="Votre adresse email utilisée pour la connexion. Ne peut pas être modifiée."></app-tooltip>
                    </label>
                    <input 
                      type="email" 
                      class="form-input readonly" 
                      [value]="userProfile?.email || 'Non disponible'"
                      readonly>
                  </div>

                  <div class="form-group">
                    <label class="form-label">
                      Téléphone
                      <app-tooltip text="Votre numéro de téléphone (optionnel)."></app-tooltip>
                    </label>
                    <input 
                      type="tel" 
                      class="form-input" 
                      formControlName="phone"
                      [readonly]="!isEditing"
                      [class.readonly]="!isEditing"
                      placeholder="+212 6XX XXX XXX">
                  </div>

                  <div class="form-group">
                    <label class="form-label">
                      Rôle
                      <app-tooltip text="Votre rôle dans l'application. Défini par l'administrateur."></app-tooltip>
                    </label>
                    <input 
                      type="text" 
                      class="form-input readonly" 
                      [value]="userProfile?.role || 'USER'"
                      readonly>
                  </div>

                  <div class="form-group">
                    <label class="form-label">
                      Date de création
                      <app-tooltip text="Date à laquelle votre compte a été créé."></app-tooltip>
                    </label>
                    <input 
                      type="text" 
                      class="form-input readonly" 
                      [value]="userProfile?.createdAt ? formatDate(userProfile?.createdAt || '') : 'Non disponible'"
                      readonly>
                  </div>
                </div>
              </form>
            </div>

                        <!-- Account Actions Card -->
            <div class="card" *ngIf="userProfile">
              <h3 class="card-title">Actions du Compte</h3>
              <div class="actions-list">
                <button class="action-item danger" (click)="confirmDeleteAccount()">
                  <div class="action-icon">🗑️</div>
                  <div class="action-content">
                    <div class="action-title">Supprimer le compte</div>
                    <div class="action-desc">Cette action est irréversible. Tous vos établissements seront également supprimés.</div>
                  </div>
                </button>
              </div>
            </div>

            <!-- Establishments Summary Card -->
            <ng-container *ngIf="userProfile?.establishments as establishments">
              <div class="card" *ngIf="establishments.length > 0">
                <h3 class="card-title">Mes Établissements ({{ establishments.length }})</h3>
                <div class="establishments-list">
                  <div class="establishment-item" *ngFor="let est of establishments">
                  <div class="est-info">
                    <div class="est-name">{{ est.name }}</div>
                    <div class="est-meta">
                      <span class="est-type">{{ est.type }}</span>
                      <span class="est-status" [class.active]="est.status === 'ACTIVE'">{{ est.status }}</span>
                    </div>
                  </div>
                  <a (click)="viewEstablishment(est.id)" class="est-link" style="cursor: pointer;">Voir →</a>
                </div>
              </div>
            </div>
            </ng-container>
          </div>
        </main>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal-overlay" *ngIf="showDeleteModal">
      <div class="modal-backdrop" (click)="showDeleteModal = false"></div>
      <div class="modal-dialog" (click)="$event.stopPropagation()">
        <div class="modal-header">
          <h2 class="modal-title">Confirmer la suppression</h2>
          <button class="modal-close" (click)="showDeleteModal = false">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
        <div class="modal-body">
          <p>Êtes-vous sûr de vouloir supprimer votre compte ?</p>
          <p class="warning-text">Cette action est irréversible. Tous vos établissements et données seront définitivement supprimés.</p>
          <div class="form-group">
            <label class="form-label">Tapez "SUPPRIMER" pour confirmer :</label>
            <input 
              type="text" 
              class="form-input" 
              [(ngModel)]="deleteConfirmation"
              placeholder="SUPPRIMER">
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" (click)="showDeleteModal = false">Annuler</button>
          <button 
            class="btn-danger" 
            (click)="deleteAccount()" 
            [disabled]="deleteConfirmation !== 'SUPPRIMER' || isDeleting">
            <span *ngIf="!isDeleting">Supprimer définitivement</span>
            <span *ngIf="isDeleting">Suppression...</span>
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    /* Reuse dashboard styles from comprehensive-results */
    .dashboard-layout {
      display: flex;
      min-height: 100vh;
      background: #F9FAF7;
    }

    .dashboard-sidebar {
      width: 260px;
      background: #FFFFFF;
      border-right: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      flex-direction: column;
      position: fixed;
      height: 100vh;
      left: 0;
      top: 0;
      z-index: 100;
    }

    .sidebar-header {
      padding: 24px 20px;
      border-bottom: 1px solid rgba(0, 0, 0, 0.06);
    }

    .sidebar-logo {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .logo-icon {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: linear-gradient(135deg, #4EA8DE, #6BCF9D);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      color: white;
    }

    .logo-text {
      display: flex;
      flex-direction: column;
    }

    .logo-title {
      font-weight: 700;
      font-size: 16px;
      color: #3A3A3A;
      line-height: 1.2;
    }

    .logo-subtitle {
      font-size: 12px;
      color: #6B7280;
      font-weight: 500;
    }

    .sidebar-nav {
      flex: 1;
      padding: 16px 12px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      border-radius: 10px;
      text-decoration: none;
      color: #6B7280;
      font-weight: 600;
      font-size: 14px;
      transition: all 0.2s ease;
      cursor: pointer;
    }

    .nav-item:hover {
      background: rgba(78, 168, 222, 0.08);
      color: #4EA8DE;
    }

    .nav-item.active {
      background: linear-gradient(135deg, rgba(78, 168, 222, 0.12), rgba(107, 207, 157, 0.08));
      color: #4EA8DE;
      border: 1px solid rgba(78, 168, 222, 0.2);
    }

    .nav-icon {
      font-size: 18px;
      width: 24px;
      text-align: center;
    }

    .dashboard-main {
      flex: 1;
      margin-left: 260px;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }

    .dashboard-header {
      background: #FFFFFF;
      border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      padding: 20px 32px;
    }

    .header-title {
      font-size: 24px;
      font-weight: 700;
      color: #1F2937;
      margin: 0;
    }

    .header-subtitle {
      font-size: 14px;
      color: #6B7280;
      margin: 4px 0 0;
    }

    .dashboard-content {
      flex: 1;
      padding: 32px;
      max-width: 1200px;
      margin: 0 auto;
      width: 100%;
    }

    .content-loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 400px;
      gap: 16px;
    }

    .error-banner {
      background: #FEF3C7;
      border: 1px solid #FCD34D;
      border-radius: 12px;
      padding: 16px 20px;
      margin-bottom: 24px;
    }

    .error-banner-content {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .error-banner-icon {
      font-size: 20px;
      flex-shrink: 0;
    }

    .error-banner-text {
      flex: 1;
      color: #92400E;
      font-size: 14px;
      font-weight: 500;
    }

    .error-banner-actions {
      display: flex;
      gap: 8px;
      flex-shrink: 0;
    }

    .btn-link {
      background: none;
      border: none;
      color: #92400E;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      padding: 4px 8px;
      text-decoration: underline;
      transition: color 0.2s ease;
    }

    .btn-link:hover {
      color: #78350F;
    }

    .loading-spinner {
      width: 48px;
      height: 48px;
      border: 4px solid rgba(78, 168, 222, 0.1);
      border-top-color: #4EA8DE;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .content-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 24px;
    }

    .card {
      background: #FFFFFF;
      border-radius: 16px;
      padding: 24px;
      border: 1px solid rgba(0, 0, 0, 0.06);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
    }

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .card-title {
      font-size: 18px;
      font-weight: 700;
      color: #1F2937;
      margin: 0;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 20px;
    }

    .form-group {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .form-label {
      font-size: 14px;
      font-weight: 600;
      color: #1F2937;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .form-input {
      padding: 12px 16px;
      border: 1.5px solid rgba(0, 0, 0, 0.1);
      border-radius: 10px;
      font-size: 14px;
      color: #1F2937;
      transition: all 0.2s ease;
      background: #FFFFFF;
    }

    .form-input:focus {
      outline: none;
      border-color: #4EA8DE;
      box-shadow: 0 0 0 3px rgba(78, 168, 222, 0.1);
    }

    .form-input.readonly {
      background: #F9FAFB;
      color: #6B7280;
      cursor: not-allowed;
    }

    .form-error {
      font-size: 12px;
      color: #EF4444;
    }

    .form-hint {
      font-size: 12px;
      color: #9CA3AF;
    }

    .actions-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .action-item {
      display: flex;
      align-items: flex-start;
      gap: 16px;
      padding: 16px;
      border-radius: 12px;
      border: 1.5px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      cursor: pointer;
      transition: all 0.2s ease;
      text-align: left;
      width: 100%;
    }

    .action-item:hover {
      border-color: rgba(239, 68, 68, 0.3);
      background: rgba(239, 68, 68, 0.05);
    }

    .action-item.danger:hover {
      border-color: rgba(239, 68, 68, 0.4);
      background: rgba(239, 68, 68, 0.08);
    }

    .action-icon {
      font-size: 24px;
      flex-shrink: 0;
    }

    .action-content {
      flex: 1;
    }

    .action-title {
      font-size: 15px;
      font-weight: 700;
      color: #1F2937;
      margin-bottom: 4px;
    }

    .action-desc {
      font-size: 13px;
      color: #6B7280;
      line-height: 1.4;
    }

    .establishments-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .establishment-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      border-radius: 12px;
      background: rgba(78, 168, 222, 0.04);
      border: 1px solid rgba(78, 168, 222, 0.1);
    }

    .est-name {
      font-size: 15px;
      font-weight: 700;
      color: #1F2937;
      margin-bottom: 4px;
    }

    .est-meta {
      display: flex;
      gap: 12px;
      font-size: 12px;
      color: #6B7280;
    }

    .est-type {
      text-transform: uppercase;
      font-weight: 600;
    }

    .est-status {
      padding: 4px 8px;
      border-radius: 6px;
      background: rgba(107, 114, 128, 0.1);
      color: #6B7280;
      font-weight: 600;
    }

    .est-status.active {
      background: rgba(16, 185, 129, 0.1);
      color: #10B981;
    }

    .est-link {
      color: #4EA8DE;
      font-weight: 600;
      text-decoration: none;
      font-size: 14px;
    }

    .est-link:hover {
      text-decoration: underline;
    }

    .btn-primary {
      background: linear-gradient(135deg, #4EA8DE, #6BCF9D);
      color: #FFFFFF;
      border: none;
      padding: 12px 24px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .btn-primary:hover:not(:disabled) {
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(78, 168, 222, 0.3);
    }

    .btn-primary:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .btn-secondary {
      background: #FFFFFF;
      color: #4EA8DE;
      border: 1.5px solid #4EA8DE;
      padding: 10px 20px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .btn-secondary:hover {
      background: rgba(78, 168, 222, 0.08);
    }

    .btn-danger {
      background: #EF4444;
      color: #FFFFFF;
      border: none;
      padding: 12px 24px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .btn-danger:hover:not(:disabled) {
      background: #DC2626;
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
    }

    .btn-danger:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    /* Modal */
    .modal-overlay {
      position: fixed;
      inset: 0;
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .modal-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(4px);
    }

    .modal-dialog {
      position: relative;
      background: #FFFFFF;
      border-radius: 20px;
      width: min(500px, calc(100vw - 64px));
      max-height: calc(100vh - 64px);
      display: flex;
      flex-direction: column;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }

    .modal-header {
      padding: 24px;
      border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .modal-title {
      font-size: 20px;
      font-weight: 700;
      color: #1F2937;
      margin: 0;
    }

    .modal-close {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      border: 1px solid rgba(0, 0, 0, 0.1);
      background: #FFFFFF;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
      color: #6B7280;
    }

    .modal-close:hover {
      background: rgba(239, 68, 68, 0.1);
      border-color: rgba(239, 68, 68, 0.3);
      color: #EF4444;
    }

    .modal-body {
      padding: 24px;
      overflow-y: auto;
      flex: 1;
    }

    .modal-body p {
      margin: 0 0 12px;
      color: #1F2937;
      line-height: 1.5;
    }

    .warning-text {
      color: #EF4444 !important;
      font-weight: 600;
    }

    .modal-footer {
      padding: 20px 24px;
      border-top: 1px solid rgba(0, 0, 0, 0.08);
      display: flex;
      justify-content: flex-end;
      gap: 12px;
    }

    /* Profile Image Styles */
    .card-profile-image {
      grid-column: 1 / -1;
    }

    .profile-image-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      padding: 20px 0;
    }

    .profile-image-wrapper {
      position: relative;
      width: 160px;
      height: 160px;
    }

    .profile-image {
      width: 160px;
      height: 160px;
      border-radius: 50%;
      object-fit: cover;
      border: 4px solid #FFFFFF;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
    }

    .profile-image-overlay {
      position: absolute;
      inset: 0;
      border-radius: 50%;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      opacity: 0;
      transition: opacity 0.2s ease;
      cursor: pointer;
    }

    .profile-image-wrapper:hover .profile-image-overlay {
      opacity: 1;
    }

    .image-upload-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      color: #FFFFFF;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
    }

    .image-upload-btn svg {
      width: 32px;
      height: 32px;
    }

    .profile-name {
      text-align: center;
    }

    .profile-name h2 {
      font-size: 24px;
      font-weight: 700;
      color: #1F2937;
      margin: 0 0 4px;
    }

    .profile-email {
      font-size: 14px;
      color: #6B7280;
      margin: 0;
    }
  `]
})
export class ProfileComponent implements OnInit, OnDestroy {
  userProfile: UserProfile | null = null;
  profileForm: FormGroup | null = null;
  isLoading = true;
  errorMessage = '';
  isEditing = false;
  isSaving = false;
  isDeleting = false;
  showDeleteModal = false;
  deleteConfirmation = '';
  profileImageUrl: string | null = null;
  defaultAvatar = 'https://ui-avatars.com/api/?name=User&background=4EA8DE&color=fff&size=200';
  selectedImageFile: File | null = null;

  getAvatarUrl(): string {
    if (this.profileImageUrl) {
      return this.profileImageUrl;
    }
    if (this.userProfile?.firstName && this.userProfile?.lastName) {
      const name = `${this.userProfile.firstName} ${this.userProfile.lastName}`;
      return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=4EA8DE&color=fff&size=200`;
    }
    if (this.userProfile?.email) {
      const name = this.userProfile.email.split('@')[0];
      return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=4EA8DE&color=fff&size=200`;
    }
    return this.defaultAvatar;
  }

  getAvatarAlt(): string {
    if (this.userProfile?.firstName && this.userProfile?.lastName) {
      return `${this.userProfile.firstName} ${this.userProfile.lastName}`;
    }
    if (this.userProfile?.email) {
      return this.userProfile.email.split('@')[0];
    }
    return 'Utilisateur';
  }
  private authSubscription?: Subscription;
  private routerSubscription?: Subscription;

  constructor(
    private apiService: ApiService,
    public authService: AuthService,
    private fb: FormBuilder,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Initialiser le formulaire d'abord pour que la page s'affiche immédiatement
    this.initEmptyForm();
    // Charger le profil immédiatement
    console.log('=== ngOnInit: Starting profile load ===');
    this.loadProfile();
    
    // Écouter les changements d'authentification
    this.authSubscription = this.authService.isAuthenticated$.subscribe(isAuthenticated => {
      console.log('Auth state changed:', isAuthenticated);
      if (isAuthenticated) {
        // Si l'utilisateur vient de se connecter, attendre un peu puis recharger le profil
        setTimeout(() => {
          const token = this.authService.getToken();
          console.log('Token after auth change:', token ? 'Present' : 'Missing');
          if (token) {
            console.log('User authenticated, reloading profile...');
            this.loadProfile();
          } else {
            // Token manquant malgré isAuthenticated = true, réessayer après un délai
            setTimeout(() => {
              const retryToken = this.authService.getToken();
              if (retryToken) {
                console.log('Token found on retry, reloading profile...');
                this.loadProfile();
              } else {
                // Si toujours pas de token après plusieurs tentatives, réessayer encore
                setTimeout(() => {
                  const finalToken = this.authService.getToken();
                  if (finalToken) {
                    console.log('Token found on final retry, reloading profile...');
                    this.loadProfile();
                  }
                }, 300);
              }
            }, 200);
          }
        }, 200);
      } else {
        // Si l'utilisateur se déconnecte, réinitialiser
        console.log('User logged out, resetting profile');
        this.userProfile = null;
        this.initEmptyForm();
        this.errorMessage = '';
        this.isLoading = false;
      }
    });

    // Écouter les changements de route (au cas où l'utilisateur revient sur cette page après connexion)
    this.routerSubscription = this.router.events.pipe(
      filter(event => event instanceof NavigationEnd && event.url === '/profile')
    ).subscribe(() => {
      // Toujours recharger le profil quand on arrive sur cette page
      console.log('Navigated to profile page, reloading...');
      setTimeout(() => {
        this.loadProfile();
      }, 200);
    });
  }

  ngOnDestroy(): void {
    if (this.authSubscription) {
      this.authSubscription.unsubscribe();
    }
    if (this.routerSubscription) {
      this.routerSubscription.unsubscribe();
    }
  }

  loadProfile(): void {
    // Initialiser le formulaire d'abord pour que la page s'affiche
    if (!this.profileForm) {
      this.initEmptyForm();
    }
    
    // Vérifier si on a un token (vérifier plusieurs emplacements possibles)
    let token = this.authService.getToken();
    
    // Si pas de token dans auth_token, vérifier d'autres clés possibles
    if (!token) {
      token = localStorage.getItem('token') || 
              localStorage.getItem('mobile_auth_token') ||
              sessionStorage.getItem('auth_token') ||
              sessionStorage.getItem('token');
      if (token) {
        console.log('Token found in alternative location, storing in auth_token');
        localStorage.setItem('auth_token', token);
      }
    }
    
    console.log('=== LOAD PROFILE ===');
    console.log('Token exists:', !!token);
    console.log('Token length:', token ? token.length : 0);
    console.log('All localStorage keys:', Object.keys(localStorage));
    
    // Toujours essayer de charger, même sans token visible
    // (le backend peut avoir d'autres mécanismes d'authentification)
    this.isLoading = true;
    this.errorMessage = '';
    
    if (token) {
      console.log('🔄 Calling GET /auth/me with token...');
    } else {
      console.log('🔄 Calling GET /auth/me without token (will try anyway)...');
    }
    console.log('Full URL: http://localhost:8080/api/auth/me');
    
    // Charger le profil depuis l'API (essayer même sans token)
    this.apiService.get<UserProfile>('/auth/me').subscribe({
      next: (profile) => {
        console.log('✅ SUCCESS! Profile loaded:', profile);
        console.log('Raw profile object:', JSON.stringify(profile, null, 2));
        console.log('firstName:', profile.firstName);
        console.log('lastName:', profile.lastName);
        console.log('email:', profile.email);
        console.log('phone:', profile.phone);
        
        // Vérifier que les données sont présentes
        if (!profile.firstName || !profile.lastName) {
          console.warn('⚠️ WARNING: Profile missing firstName or lastName!');
          console.warn('Full profile:', profile);
        }
        
        // S'assurer que les données sont bien présentes avant d'initialiser
        if (profile && (profile.firstName || profile.lastName || profile.email)) {
          this.userProfile = profile;
          this.initForm(); // Initialiser le formulaire avec les données (en lecture seule)
          this.loadProfileImage();
          this.isLoading = false;
          this.errorMessage = '';
          console.log('✅ Profile form initialized with data');
        } else {
          console.error('❌ Profile data is empty or invalid!', profile);
          this.userProfile = null;
          this.isLoading = false;
          this.errorMessage = 'Les données du profil sont vides ou invalides.';
        }
      },
      error: (error) => {
        console.error('❌ ERROR loading profile!');
        console.error('Error object:', error);
        console.error('Error status:', error.status);
        console.error('Error message:', error.message);
        console.error('Error error:', error.error);
        console.error('Full error:', JSON.stringify(error, null, 2));
        
        this.isLoading = false;
        
        // Afficher un message seulement pour erreurs serveur
        if (error.status === 0) {
          this.errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://localhost:8080.';
          console.error('❌ Backend not reachable!');
        } else if (error.status === 401 || error.status === 403) {
          console.warn('⚠️ Token invalid or expired (401/403)');
          console.warn('Current token:', token ? (token.substring(0, 50) + '...') : 'null');
          this.errorMessage = 'Token invalide ou expiré. Veuillez vous reconnecter.';
        } else {
          this.errorMessage = `Erreur lors du chargement (${error.status || 'inconnu'}).`;
          console.error('❌ Unknown error:', error);
        }
        
        // Garder le formulaire vide
        this.userProfile = null;
        if (!this.profileForm) {
          this.initEmptyForm();
        }
      }
    });
  }

  initEmptyForm(): void {
    // Initialiser un formulaire vide en mode lecture seule
    this.profileForm = this.fb.group({
      firstName: [{ value: '', disabled: true }],
      lastName: [{ value: '', disabled: true }],
      phone: [{ value: '', disabled: true }]
    });
    this.isEditing = false;
  }

  loadProfileImage(): void {
    if (!this.userProfile?.id) return;
    const storedImage = localStorage.getItem(`profile_image_${this.userProfile.id}`);
    if (storedImage) {
      this.profileImageUrl = storedImage;
    }
  }

  onImageSelected(event: any): void {
    const file = event.target.files[0];
    if (!file) return;
    
    if (file.size > 5 * 1024 * 1024) {
      alert('L\'image est trop volumineuse. Taille maximale : 5 MB');
      return;
    }

    if (!file.type.startsWith('image/')) {
      alert('Veuillez sélectionner une image valide.');
      return;
    }

    this.selectedImageFile = file;
    const reader = new FileReader();
    reader.onload = (e: any) => {
      this.profileImageUrl = e.target.result;
      if (this.userProfile?.id) {
        localStorage.setItem(`profile_image_${this.userProfile.id}`, e.target.result);
      }
    };
    reader.readAsDataURL(file);
  }

  onImageError(event: any): void {
    event.target.src = this.defaultAvatar;
  }

  initForm(): void {
    if (!this.userProfile) {
      console.warn('⚠️ initForm called but userProfile is null!');
      this.initEmptyForm();
      return;
    }
    console.log('📝 Initializing form with profile data:', {
      firstName: this.userProfile.firstName,
      lastName: this.userProfile.lastName,
      phone: this.userProfile.phone,
      email: this.userProfile.email
    });
    
    // Vérifier que les données sont bien présentes
    if (!this.userProfile.firstName || !this.userProfile.lastName) {
      console.error('❌ Profile data incomplete!', this.userProfile);
    }
    
    // Initialiser le formulaire avec les données en mode lecture seule
    this.profileForm = this.fb.group({
      firstName: [{ value: this.userProfile.firstName || '', disabled: true }, [Validators.required]],
      lastName: [{ value: this.userProfile.lastName || '', disabled: true }, [Validators.required]],
      phone: [{ value: this.userProfile.phone || '', disabled: true }]
    });
    
    // Par défaut, pas en mode édition (lecture seule)
    this.isEditing = false;
    
    // Utiliser getRawValue() pour obtenir les valeurs même si les champs sont disabled
    const formValues = this.profileForm.getRawValue();
    console.log('✅ Form initialized. Fields (getRawValue):', formValues);
    console.log('✅ Form initialized. Fields (get):', {
      firstName: this.profileForm.get('firstName')?.value,
      lastName: this.profileForm.get('lastName')?.value,
      phone: this.profileForm.get('phone')?.value
    });
  }

  startEdit(): void {
    // Si pas de profil, ne rien faire
    if (!this.userProfile) {
      return;
    }
    // Activer le mode édition
    this.isEditing = true;
    // Activer les champs du formulaire
    if (this.profileForm) {
      this.profileForm.get('firstName')?.enable();
      this.profileForm.get('lastName')?.enable();
      this.profileForm.get('phone')?.enable();
    }
  }

  cancelEdit(): void {
    // Désactiver le mode édition
    this.isEditing = false;
    // Recharger les données originales depuis userProfile
    if (this.userProfile && this.profileForm) {
      this.profileForm.patchValue({
        firstName: this.userProfile.firstName || '',
        lastName: this.userProfile.lastName || '',
        phone: this.userProfile.phone || ''
      });
      // Désactiver les champs
      this.profileForm.get('firstName')?.disable();
      this.profileForm.get('lastName')?.disable();
      this.profileForm.get('phone')?.disable();
    }
  }

  saveProfile(): void {
    if (!this.profileForm || this.profileForm.invalid) return;
    
    // Vérifier si on a un token avant de sauvegarder
    const token = this.authService.getToken();
    if (!token) {
      alert('Vous devez être connecté pour sauvegarder votre profil. Veuillez vous connecter d\'abord.');
      return;
    }
    
    this.isSaving = true;
    const formValue = this.profileForm.value;
    this.apiService.put<UserProfile>('/auth/me', formValue).subscribe({
      next: (updated) => {
        this.userProfile = updated;
        this.initForm(); // Réinitialiser avec les nouvelles données
        this.isSaving = false;
        alert('Profil mis à jour avec succès!');
      },
      error: (error) => {
        if (error.status === 401 || error.status === 403) {
          alert('Session expirée. Veuillez vous reconnecter pour sauvegarder.');
        } else {
          alert('Erreur lors de la mise à jour du profil. Veuillez réessayer.');
        }
        this.isSaving = false;
        console.error('Error updating profile:', error);
      }
    });
  }

  confirmDeleteAccount(): void {
    this.showDeleteModal = true;
    this.deleteConfirmation = '';
  }

  deleteAccount(): void {
    if (this.deleteConfirmation !== 'SUPPRIMER') return;
    this.isDeleting = true;
    this.apiService.delete('/auth/me').subscribe({
      next: () => {
        this.authService.logout();
      },
      error: (error) => {
        this.errorMessage = 'Erreur lors de la suppression du compte.';
        this.isDeleting = false;
        this.showDeleteModal = false;
        console.error('Error deleting account:', error);
      }
    });
  }

  formatDate(date: string | null | undefined): string {
    if (!date) return '';
    try {
      return new Date(date).toLocaleDateString('fr-FR');
    } catch {
      return '';
    }
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  clearTokenAndReload(): void {
    console.log('Clearing token and reloading...');
    localStorage.removeItem('auth_token');
    this.authService['isAuthenticatedSubject'].next(false);
    this.userProfile = null;
    this.initEmptyForm();
    // Recharger après un court délai
    setTimeout(() => {
      this.loadProfile();
    }, 100);
  }

  viewEstablishment(establishmentId: number): void {
    localStorage.setItem('selectedEstablishmentId', establishmentId.toString());
    this.router.navigate(['/mobile/results/comprehensive'], {
      queryParams: {
        establishmentId: establishmentId
      }
    });
  }
}

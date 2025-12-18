import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { EstablishmentService, Establishment } from '../../services/establishment.service';

@Component({
  selector: 'app-establishments',
  template: `
    <div class="establishments-container">
      <app-navigation></app-navigation>
      <div class="establishments-content">
        <div class="page-header">
          <div>
            <h1>Mes établissements</h1>
            <p>Gérez vos établissements et leurs configurations</p>
          </div>
          <button class="btn-primary" (click)="createNew()">
            <span>+</span> Nouvel établissement
          </button>
        </div>
        
        <div *ngIf="isLoading" class="loading">
          <p>Chargement des établissements...</p>
        </div>
        
        <div *ngIf="successMessage" class="success-message">
          {{ successMessage }}
        </div>
        
        <div *ngIf="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>
        
        <div *ngIf="!isLoading && establishments.length === 0" class="empty-state">
          <div class="empty-icon"></div>
          <h3>Aucun établissement</h3>
          <p>Créez votre premier établissement pour commencer</p>
          <button class="btn-primary" (click)="createNew()">
            Créer un établissement
          </button>
        </div>
        
        <div *ngIf="!isLoading && establishments.length > 0" class="establishments-grid">
          <div *ngFor="let establishment of establishments" class="establishment-card">
            <div class="card-header">
              <div class="establishment-info">
                <h3>{{ establishment.name }}</h3>
                <span class="establishment-type">{{ getTypeLabel(establishment.type) }}</span>
              </div>
              <div class="card-actions">
                <button class="btn-edit" (click)="editEstablishment(establishment.id)" title="Modifier">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                  <span>Modifier</span>
                </button>
                <button class="btn-delete" (click)="deleteEstablishment(establishment.id)" title="Supprimer">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"></polyline>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                  </svg>
                  <span>Supprimer</span>
                </button>
              </div>
            </div>
            
            <div class="card-body">
              <div class="info-row" *ngIf="establishment['numberOfBeds']">
                <span class="label">Nombre de lits:</span>
                <span class="value">{{ establishment['numberOfBeds'] }}</span>
              </div>
              <div class="info-row" *ngIf="establishment['address']">
                <span class="label">Adresse:</span>
                <span class="value">{{ establishment['address'] }}</span>
              </div>
              <div class="info-row" *ngIf="establishment['irradiationClass']">
                <span class="label">Zone d'irradiation:</span>
                <span class="value">{{ establishment['irradiationClass'] }}</span>
              </div>
            </div>
            
            <div class="card-footer">
              <button class="btn-secondary" (click)="viewDetails(establishment.id)">
                Voir les détails
              </button>
              <button class="btn-primary" (click)="selectEstablishment(establishment.id)">
                Utiliser cet établissement
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./establishments.component.scss']
})
export class EstablishmentsComponent implements OnInit {
  establishments: Establishment[] = [];
  isLoading = true;
  errorMessage = '';
  successMessage = '';

  constructor(
    private establishmentService: EstablishmentService,
    private router: Router,
    private route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    // Vérifier si on vient d'une modification réussie
    this.route.queryParams.subscribe(params => {
      if (params['updated'] === 'true') {
        this.successMessage = 'Établissement modifié avec succès !';
        setTimeout(() => {
          this.successMessage = '';
        }, 5000);
      }
    });
    
    this.loadEstablishments();
  }

  loadEstablishments(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    this.establishmentService.getUserEstablishments().subscribe({
      next: (establishments) => {
        console.log('Establishments loaded:', establishments);
        console.log('Number of establishments:', establishments.length);
        this.establishments = establishments;
        this.isLoading = false;
        // Si la liste est vide, ne pas afficher d'erreur - l'utilisateur peut créer un établissement
        if (establishments.length === 0) {
          console.warn('No establishments found. This could mean: 1) No establishments created yet, 2) Token expired/invalid, 3) User not authenticated');
        }
      },
      error: (error) => {
        console.error('Error loading establishments:', error);
        console.error('Error details:', {
          status: error.status,
          statusText: error.statusText,
          message: error.message,
          error: error.error
        });
        // Ne pas rediriger vers login - permettre à l'utilisateur de créer un établissement
        if (error.status === 0) {
          this.errorMessage = 'Impossible de contacter le serveur. Vérifiez que le backend est démarré.';
        } else {
          // Pour les autres erreurs, ne pas afficher de message - laisser l'utilisateur créer un établissement
          this.establishments = [];
        }
        this.isLoading = false;
      }
    });
  }

  createNew(): void {
    this.router.navigate(['/institution-choice']);
  }

  editEstablishment(id: number): void {
    // Trouver l'établissement dans la liste pour passer les données de base
    const establishment = this.establishments.find(e => e.id === id);
    if (establishment) {
      // Passer les données via queryParams pour pré-remplir même en cas d'erreur
      const params: any = { id: id };
      if (establishment.name) params.name = establishment.name;
      if (establishment.type) params.type = establishment.type;
      if (establishment['numberOfBeds']) params.numberOfBeds = establishment['numberOfBeds'];
      if (establishment['address']) params.address = establishment['address'];
      if (establishment['irradiationClass']) params.irradiationClass = establishment['irradiationClass'];
      if (establishment['latitude']) params.latitude = establishment['latitude'];
      if (establishment['longitude']) params.longitude = establishment['longitude'];
      
      this.router.navigate(['/create-establishment'], { queryParams: params });
    } else {
      this.router.navigate(['/create-establishment'], { queryParams: { id: id } });
    }
  }

  deleteEstablishment(id: number): void {
    if (confirm('Êtes-vous sûr de vouloir supprimer cet établissement ? Cette action est irréversible.')) {
      // TODO: Implémenter la suppression dans le service
      this.establishmentService.deleteEstablishment(id).subscribe({
        next: () => {
          this.loadEstablishments();
        },
        error: (error) => {
          alert('Erreur lors de la suppression: ' + (error.error?.message || error.message));
        }
      });
    }
  }

  viewDetails(id: number): void {
    // Workflow normal : voir les détails = voir les résultats complets
    this.router.navigate(['/mobile/results/comprehensive'], { queryParams: { establishmentId: id } });
  }

  selectEstablishment(id: number): void {
    // Stocker l'ID de l'établissement sélectionné
    localStorage.setItem('selectedEstablishmentId', id.toString());
    // Rediriger directement vers la page des résultats complets de l'établissement
    this.router.navigate(['/mobile/results/comprehensive'], { 
      queryParams: { 
        establishmentId: id
      } 
    });
  }

  getTypeLabel(type: string): string {
    const types: { [key: string]: string } = {
      'CHU': 'CHU',
      'HOPITAL_REGIONAL': 'Hôpital Régional',
      'HOPITAL_PREFECTORAL': 'Hôpital Préfectoral',
      'HOPITAL_PROVINCIAL': 'Hôpital Provincial',
      'CENTRE_REGIONAL_ONCOLOGIE': 'Centre d\'Oncologie',
      'CENTRE_HEMODIALYSE': 'Centre d\'Hémodialyse',
      'CENTRE_REEDUCATION': 'Centre de Rééducation',
      'CENTRE_ADDICTOLOGIE': 'Centre d\'Addictologie',
      'CENTRE_SOINS_PALLIATIFS': 'Centre de Soins Palliatifs',
      'UMH': 'UMH',
      'UMP': 'UMP',
      'UPH': 'UPH',
      'CENTRE_SANTE_PRIMAIRE': 'Centre de Santé Primaire',
      'CLINIQUE_PRIVEE': 'Clinique Privée'
    };
    return types[type] || type;
  }
}


import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface EstablishmentTypeNode {
  id: string;
  name: string;
  backendValue?: string;
  children?: EstablishmentTypeNode[];
}

const TYPE_TREE: EstablishmentTypeNode[] = [
  { id: 'chu', name: 'CHU (Centre Hospitalier Universitaire)', backendValue: 'CHU' },
  {
    id: 'hopitaux',
    name: 'Hôpitaux',
    children: [
      { id: 'hopital_regional', name: 'Hôpital Régional', backendValue: 'HOPITAL_REGIONAL' },
      { id: 'hopital_provincial', name: 'Hôpital Provincial', backendValue: 'HOPITAL_PROVINCIAL' },
      { id: 'hopital_prefectoral', name: 'Hôpital Préfectoral', backendValue: 'HOPITAL_PREFECTORAL' },
      { id: 'hopital_specialise', name: 'Hôpital Spécialisé', backendValue: 'HOPITAL_SPECIALISE' }
    ]
  },
  {
    id: 'centres_specialises',
    name: 'Centres de Soins Spécialisés',
    children: [
      { id: 'centre_regional_oncologie', name: "Centre Régional d'Oncologie", backendValue: 'CENTRE_REGIONAL_ONCOLOGIE' },
      { id: 'centre_hemodialyse', name: "Centre d'Hémodialyse", backendValue: 'CENTRE_HEMODIALYSE' },
      { id: 'centre_reeducation', name: 'Centre de Rééducation', backendValue: 'CENTRE_REEDUCATION' },
      { id: 'centre_addictologie', name: "Centre d'Addictologie", backendValue: 'CENTRE_ADDICTOLOGIE' }
    ]
  },
  {
    id: 'urgences',
    name: "Dispositifs d'Urgences",
    children: [
      { id: 'umh', name: 'UMH (Urgences Médico-Hospitalières)', backendValue: 'UMH' },
      { id: 'ump', name: 'UMP (Urgences Médicales de Proximité)', backendValue: 'UMP' },
      { id: 'uph', name: 'UPH (Urgences Pré-Hospitalières)', backendValue: 'UPH' }
    ]
  },
  { id: 'centre_sante_primaire', name: 'Centre de Santé Primaire', backendValue: 'CENTRE_SANTE_PRIMAIRE' },
  { id: 'clinique_privee', name: 'Clinique Privée', backendValue: 'CLINIQUE_PRIVEE' },
  { id: 'autre', name: 'Autre', backendValue: 'CENTRE_SANTE_PRIMAIRE' }
];

@Component({
  selector: 'app-hierarchical-type-selector',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button type="button" class="hts" (click)="open = true">
      <span class="hts-text">{{ selectedLabel || 'Sélectionnez le type' }}</span>
      <span class="hts-caret">▾</span>
    </button>

    <div class="hts-backdrop" *ngIf="open" (click)="close()"></div>
    <div class="hts-dialog" *ngIf="open">
      <div class="hts-header">
        <button type="button" class="hts-close" (click)="close()">✕</button>
        <div class="hts-title">{{ dialogTitle }}</div>
      </div>

      <div class="hts-list">
        <ng-container *ngIf="!stack.length">
          <button
            class="hts-item"
            type="button"
            *ngFor="let node of tree"
            (click)="selectNode(node)"
          >
            <span>{{ node.name }}</span>
            <span class="hts-next" *ngIf="node.children?.length">›</span>
          </button>
        </ng-container>

        <ng-container *ngIf="stack.length">
          <button class="hts-item hts-back" type="button" (click)="pop()">
            ← Retour
          </button>
          <button
            class="hts-item"
            type="button"
            *ngFor="let child of stack[stack.length - 1].children"
            (click)="selectLeaf(child)"
          >
            <span>{{ child.name }}</span>
            <span class="hts-check" *ngIf="child.backendValue === value">✓</span>
          </button>
        </ng-container>
      </div>
    </div>
  `,
  styles: [
    `
      .hts {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 14px 14px;
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.12);
        background: #fff;
        cursor: pointer;
      }
      .hts-icon {
        opacity: 0.8;
      }
      .hts-text {
        flex: 1;
        text-align: left;
        font-weight: 600;
        color: var(--soft-grey);
      }
      .hts-caret {
        opacity: 0.6;
      }

      .hts-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.35);
        z-index: 1000;
      }
      .hts-dialog {
        position: fixed;
        z-index: 1001;
        left: 50%;
        top: 50%;
        transform: translate(-50%, -50%);
        width: min(520px, calc(100vw - 24px));
        max-height: min(640px, calc(100vh - 24px));
        background: #fff;
        border-radius: 16px;
        overflow: hidden;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.25);
      }
      .hts-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 14px 16px;
        border-bottom: 1px solid rgba(0, 0, 0, 0.08);
      }
      .hts-close {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        background: #fff;
        cursor: pointer;
      }
      .hts-title {
        font-weight: 800;
      }
      .hts-list {
        padding: 10px;
        overflow: auto;
        max-height: calc(min(640px, calc(100vh - 24px)) - 58px);
      }
      .hts-item {
        width: 100%;
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 12px;
        border-radius: 12px;
        border: none;
        background: transparent;
        cursor: pointer;
        text-align: left;
      }
      .hts-item:hover {
        background: rgba(78, 168, 222, 0.08);
      }
      .hts-next {
        opacity: 0.6;
        font-weight: 900;
      }
      .hts-check {
        color: var(--medical-blue);
        font-weight: 900;
      }
      .hts-back {
        font-weight: 800;
      }
    `
  ]
})
export class HierarchicalTypeSelectorComponent {
  @Input() value: string | null = null;
  @Output() valueChange = new EventEmitter<string>();

  tree = TYPE_TREE;
  open = false;
  stack: EstablishmentTypeNode[] = [];

  get dialogTitle(): string {
    return this.stack.length ? this.stack[this.stack.length - 1].name : 'Sélectionner le type';
  }

  get selectedLabel(): string | null {
    const find = (nodes: EstablishmentTypeNode[]): string | null => {
      for (const n of nodes) {
        if (n.backendValue && n.backendValue === this.value) return n.name;
        if (n.children?.length) {
          const inner = find(n.children);
          if (inner) return inner;
        }
      }
      return null;
    };
    return this.value ? find(this.tree) : null;
  }

  close(): void {
    this.open = false;
    this.stack = [];
  }

  pop(): void {
    this.stack.pop();
  }

  selectNode(node: EstablishmentTypeNode): void {
    if (node.children?.length) {
      this.stack.push(node);
      return;
    }
    if (node.backendValue) {
      this.value = node.backendValue;
      this.valueChange.emit(node.backendValue);
      this.close();
    }
  }

  selectLeaf(node: EstablishmentTypeNode): void {
    if (!node.backendValue) return;
    this.value = node.backendValue;
    this.valueChange.emit(node.backendValue);
    this.close();
  }
}



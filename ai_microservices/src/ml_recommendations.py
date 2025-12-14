"""
Module pour les recommandations intelligentes basées sur règles + patterns similaires
NOTA: Le ROI est calculé via formule déterministe dans le backend Java, pas avec ML
"""
from __future__ import annotations

from pathlib import Path
from typing import Dict, List, Optional

import numpy as np

from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")


def get_ml_recommendations(
    establishment_type: str,
    number_of_beds: int,
    monthly_consumption: float,
    installable_surface: Optional[float],
    irradiation_class: str,
    recommended_pv_power: float,
    recommended_battery: float,
    autonomy: float,
    roi_years: Optional[float] = None,  # ROI calculé côté backend (formule déterministe)
    similar_establishments: Optional[List[Dict]] = None,
) -> Dict:
    """
    Génère des recommandations intelligentes basées sur règles + patterns similaires
    
    Approche "Hybrid Decision System" :
    - Règles simples pour cas évidents (déterministes)
    - Comparaison avec établissements similaires pour patterns (léger ML)
    - PAS de prédiction ROI avec ML (calculé via formule déterministe)
    """
    recommendations = []
    
    # ============================================
    # 1. RECOMMANDATIONS BASÉES SUR RÈGLES SIMPLES
    # ============================================
    
    # Règle 1 : Autonomie énergétique
    if autonomy < 30:
        recommendations.append({
            "type": "warning",
            "category": "performance",
            "message": f"Autonomie énergétique faible ({autonomy:.1f}%)",
            "suggestion": "Augmenter la surface PV installable pour améliorer l'autonomie",
            "priority": "high",
            "confidence": "high"
        })
    elif autonomy < 50:
        recommendations.append({
            "type": "info",
            "category": "optimization",
            "message": f"Autonomie modérée ({autonomy:.1f}%)",
            "suggestion": "Envisager d'augmenter la surface PV pour atteindre >50% d'autonomie",
            "priority": "medium",
            "confidence": "high"
        })
    elif autonomy >= 100:
        recommendations.append({
            "type": "success",
            "category": "performance",
            "message": f"Excellente autonomie ({autonomy:.1f}%)",
            "suggestion": "Production solaire excédentaire possible. Envisager la vente du surplus ou l'augmentation de la capacité de stockage",
            "priority": "low",
            "confidence": "high"
        })
    
    # Règle 2 : Surface installable
    if installable_surface is not None:
        # Ratio surface/consommation (m² pour 1000 kWh/mois)
        surface_per_1k_kwh = (installable_surface / monthly_consumption) * 1000 if monthly_consumption > 0 else 0
        
        if surface_per_1k_kwh < 10:
            recommendations.append({
                "type": "warning",
                "category": "constraints",
                "message": "Surface installable relativement limitée",
                "suggestion": "Optimiser la disposition des panneaux et envisager des panneaux haute efficacité",
                "priority": "medium",
                "confidence": "high"
            })
    
    # Règle 3 : ROI (si fourni, mais calculé côté backend)
    if roi_years is not None:
        if roi_years < 5.0:
            recommendations.append({
                "type": "success",
                "category": "financial",
                "message": f"ROI excellent ({roi_years:.1f} ans)",
                "suggestion": "Investissement très rentable, retour sur investissement rapide",
                "priority": "low",
                "confidence": "high"
            })
        elif roi_years < 10.0:
            recommendations.append({
                "type": "info",
                "category": "financial",
                "message": f"ROI bon ({roi_years:.1f} ans)",
                "suggestion": "Investissement rentable dans un délai raisonnable",
                "priority": "low",
                "confidence": "high"
            })
        elif roi_years > 15.0:
            recommendations.append({
                "type": "warning",
                "category": "financial",
                "message": f"ROI long ({roi_years:.1f} ans)",
                "suggestion": "Envisager d'optimiser la configuration (réduire coûts d'installation, améliorer autonomie) pour améliorer le ROI",
                "priority": "medium",
                "confidence": "high"
            })
    
    # Règle 4 : Zone solaire et production
    irradiation_factors = {"A": 1.0, "B": 0.75, "C": 0.5, "D": 0.25}
    irrad_factor = irradiation_factors.get(irradiation_class, 0.5)
    
    if irrad_factor < 0.5 and autonomy < 50:
        recommendations.append({
            "type": "info",
            "category": "environmental",
            "message": f"Zone solaire {irradiation_class} avec autonomie modérée",
            "suggestion": "La zone solaire étant moins favorable, envisager d'augmenter la surface PV pour compenser",
            "priority": "medium",
            "confidence": "high"
        })
    
    # Règle 5 : Capacité batterie vs consommation
    if monthly_consumption > 0:
        daily_consumption = monthly_consumption / 30
        battery_days_autonomy = recommended_battery / daily_consumption if daily_consumption > 0 else 0
        
        if battery_days_autonomy < 1.0:
            recommendations.append({
                "type": "warning",
                "category": "technical",
                "message": "Capacité batterie sous-dimensionnée (< 1 jour d'autonomie)",
                "suggestion": "Envisager d'augmenter la capacité de stockage pour améliorer la résilience",
                "priority": "high",
                "confidence": "high"
            })
        elif battery_days_autonomy > 3.0:
            recommendations.append({
                "type": "info",
                "category": "technical",
                "message": "Capacité batterie généreuse (> 3 jours d'autonomie)",
                "suggestion": "Excellente résilience, mais le coût peut être optimisé",
                "priority": "low",
                "confidence": "high"
            })
    
    # ============================================
    # 2. RECOMMANDATIONS BASÉES SUR PATTERNS SIMILAIRES (ML léger)
    # ============================================
    
    if similar_establishments and len(similar_establishments) > 0:
        # Analyser les établissements similaires pour identifier patterns
        similar_autonomies = [e.get("autonomy", 0.0) for e in similar_establishments if e.get("autonomy")]
        similar_rois = [e.get("roi", 0.0) for e in similar_establishments if e.get("roi")]
        similar_surfaces = [e.get("installableSurface", 0.0) for e in similar_establishments if e.get("installableSurface")]
        
        # Pattern 1 : Autonomie comparée
        if similar_autonomies:
            avg_autonomy = np.mean(similar_autonomies)
            std_autonomy = np.std(similar_autonomies) if len(similar_autonomies) > 1 else 0
            
            if autonomy < avg_autonomy - std_autonomy:
                recommendations.append({
                    "type": "warning",
                    "category": "performance",
                    "message": f"Autonomie ({autonomy:.1f}%) inférieure à la moyenne des établissements similaires ({avg_autonomy:.1f}% ± {std_autonomy:.1f}%)",
                    "suggestion": f"Les établissements similaires ont en moyenne {avg_autonomy:.1f}% d'autonomie. Envisager d'augmenter la surface PV ou d'optimiser la configuration",
                    "priority": "high",
                    "confidence": "medium"
                })
            elif autonomy > avg_autonomy + std_autonomy:
                recommendations.append({
                    "type": "success",
                    "category": "performance",
                    "message": f"Autonomie ({autonomy:.1f}%) supérieure à la moyenne des établissements similaires",
                    "suggestion": "Configuration excellente par rapport aux projets similaires",
                    "priority": "low",
                    "confidence": "medium"
                })
        
        # Pattern 2 : ROI comparé (si disponible)
        if similar_rois and roi_years is not None:
            avg_roi = np.mean(similar_rois)
            
            if roi_years > avg_roi * 1.3:
                recommendations.append({
                    "type": "warning",
                    "category": "financial",
                    "message": f"ROI ({roi_years:.1f} ans) supérieur à la moyenne des établissements similaires ({avg_roi:.1f} ans)",
                    "suggestion": "Le ROI est plus long que la moyenne. Analyser les différences de configuration pour identifier des optimisations",
                    "priority": "medium",
                    "confidence": "medium"
                })
            elif roi_years < avg_roi * 0.7:
                recommendations.append({
                    "type": "success",
                    "category": "financial",
                    "message": f"ROI ({roi_years:.1f} ans) inférieur à la moyenne des établissements similaires ({avg_roi:.1f} ans)",
                    "suggestion": "Excellent ROI par rapport aux projets similaires, investissement très rentable",
                    "priority": "low",
                    "confidence": "medium"
                })
        
        # Pattern 3 : Surface comparée
        if similar_surfaces and installable_surface is not None:
            avg_surface = np.mean([s for s in similar_surfaces if s > 0])
            
            if installable_surface < avg_surface * 0.7:
                recommendations.append({
                    "type": "info",
                    "category": "constraints",
                    "message": f"Surface installable ({installable_surface:.0f} m²) inférieure à la moyenne des établissements similaires ({avg_surface:.0f} m²)",
                    "suggestion": "Contrainte de surface identifiée. Envisager des panneaux haute efficacité pour maximiser la production",
                    "priority": "medium",
                    "confidence": "medium"
                })
    
    # ============================================
    # 3. FORMAT DE RETOUR
    # ============================================
    
    # Si aucune recommandation, ajouter une confirmation positive
    if not recommendations:
        recommendations.append({
            "type": "success",
            "category": "general",
            "message": "Configuration optimale",
            "suggestion": "La configuration actuelle est bien équilibrée",
            "priority": "low",
            "confidence": "high"
        })
    
    # Trier par priorité (high > medium > low)
    priority_order = {"high": 0, "medium": 1, "low": 2}
    recommendations.sort(key=lambda x: priority_order.get(x.get("priority", "low"), 2))
    
    return {
        "recommendations": recommendations,
        "count": len(recommendations),
        "method": "hybrid_decision_system",  # Règles + patterns similaires
        "note": "ROI calculé via formule déterministe côté backend Java, pas avec ML"
    }

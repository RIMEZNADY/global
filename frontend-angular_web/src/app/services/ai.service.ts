import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';

const AI_SERVICE_URL = 'http://localhost:8000';

export interface MLMetricsResponse {
  train: MLMetrics;
  test: MLMetrics;
  meta: MLMetricsMeta;
  improvement?: MLMetricsImprovement;
}

export interface MLMetrics {
  mae: number;
  rmse: number;
  mape: number;
}

export interface MLMetricsMeta {
  model: string;
  timestamp: string;
  features: number;
  train_rows: number;
  test_rows: number;
}

export interface MLMetricsImprovement {
  improved: boolean;
  mae_pct: number;
  rmse_pct: number;
}

export interface RetrainResponse {
  status: string;
  metrics?: any;
}

export interface LongTermForecastResponse {
  predictions: ForecastDay[];
  confidenceIntervals: ConfidenceInterval[];
  trend: string;
  method: string;
}

export interface ForecastDay {
  day: number;
  predictedConsumption: number;
  predictedPvProduction: number;
}

export interface ConfidenceInterval {
  day: number;
  consumptionLower: number;
  consumptionUpper: number;
  pvLower: number;
  pvUpper: number;
}

export interface AnomalyGraphResponse {
  anomalies: AnomalyDataPoint[];
  statistics: AnomalyStatistics;
}

export interface AnomalyDataPoint {
  datetime: string;
  isAnomaly: boolean;
  anomalyType?: string;
  anomalyScore: number;
  recommendation?: string;
  consumption: number;
  predictedConsumption: number;
  pvProduction: number;
  expectedPv: number;
  soc: number;
}

export interface AnomalyStatistics {
  totalAnomalies: number;
  highConsumptionAnomalies: number;
  lowConsumptionAnomalies: number;
  pvMalfunctionAnomalies: number;
  batteryLowAnomalies: number;
  averageAnomalyScore: number;
  mostCommonAnomalyType: string;
}

export interface MlRecommendationsResponse {
  predicted_roi_years: number;
  recommendations: Recommendation[];
  confidence: string;
}

export interface Recommendation {
  type: string;
  message: string;
  suggestion?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AiService {
  constructor(
    private apiService: ApiService,
    private http: HttpClient
  ) {}

  getMetrics(): Observable<MLMetricsResponse> {
    return this.http.get<MLMetricsResponse>(`${AI_SERVICE_URL}/metrics`);
  }

  retrain(): Observable<RetrainResponse> {
    return this.http.post<RetrainResponse>(`${AI_SERVICE_URL}/retrain`, {});
  }

  getForecast(establishmentId: number, horizonDays: number = 7): Observable<LongTermForecastResponse> {
    return this.apiService.get<LongTermForecastResponse>(
      `/establishments/${establishmentId}/forecast?horizonDays=${horizonDays}`
    );
  }

  getSeasonalForecast(establishmentId: number, season: string, year?: number): Observable<LongTermForecastResponse> {
    const yearParam = year ? `&year=${year}` : '';
    return this.apiService.get<LongTermForecastResponse>(
      `/establishments/${establishmentId}/forecast/seasonal?season=${season}${yearParam}`
    );
  }

  getAnomalies(establishmentId: number, days: number = 7): Observable<AnomalyGraphResponse> {
    return this.apiService.get<AnomalyGraphResponse>(
      `/establishments/${establishmentId}/anomalies?days=${days}`
    );
  }

  getMlRecommendations(establishmentId: number): Observable<MlRecommendationsResponse> {
    return this.apiService.get<MlRecommendationsResponse>(
      `/establishments/${establishmentId}/recommendations/ml`
    );
  }
}

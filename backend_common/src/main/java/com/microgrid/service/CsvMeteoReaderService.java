package com.microgrid.service;

import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Service pour lire les données météorologiques depuis les fichiers CSV
 */
@Service
public class CsvMeteoReaderService {

    @Value("${meteo.data.path:../ai_microservices/data_raw}")
    private String meteoDataPath;

    private final MeteoDataService meteoDataService;
    
    // Cache pour éviter de recharger les fichiers à chaque fois
    private final Map<String, Map<LocalDateTime, MeteoData>> cache = new ConcurrentHashMap<>();

    public CsvMeteoReaderService(MeteoDataService meteoDataService) {
        this.meteoDataService = meteoDataService;
    }

    /**
     * Classe pour stocker les données météo d'un pas de temps
     */
    public static class MeteoData {
        public final double temperature;
        public final double irradiance;

        public MeteoData(double temperature, double irradiance) {
            this.temperature = temperature;
            this.irradiance = irradiance;
        }
    }

    /**
     * Lit les données météo pour un datetime et une classe d'irradiation donnés
     * 
     * @param datetime Date et heure
     * @param irradiationClass Classe d'irradiation
     * @return Données météo (température, irradiance) ou null si non trouvé
     */
    public MeteoData getMeteoData(LocalDateTime datetime, MoroccanCity.IrradiationClass irradiationClass) {
        String fileName = meteoDataService.getMeteoFileName(irradiationClass);
        Map<LocalDateTime, MeteoData> fileData = cache.computeIfAbsent(fileName, this::loadCsvFile);
        
        if (fileData == null || fileData.isEmpty()) {
            return null;
        }

        // Chercher la ligne la plus proche (arrondi à 6h)
        LocalDateTime roundedDateTime = roundTo6Hours(datetime);
        
        // Chercher exactement ce datetime
        MeteoData exact = fileData.get(roundedDateTime);
        if (exact != null) {
            return exact;
        }

        // Si non trouvé, chercher le plus proche
        LocalDateTime closest = findClosestDateTime(fileData.keySet(), roundedDateTime);
        if (closest != null) {
            return fileData.get(closest);
        }

        return null;
    }

    /**
     * Charge un fichier CSV météo en mémoire
     */
    private Map<LocalDateTime, MeteoData> loadCsvFile(String fileName) {
        Map<LocalDateTime, MeteoData> data = new HashMap<>();
        
        try {
            Path filePath = Paths.get(meteoDataPath, fileName);
            
            // Si le fichier n'existe pas, essayer le chemin relatif depuis le projet
            if (!Files.exists(filePath)) {
                Path alternativePath = Paths.get("..", "ai_microservices", "data_raw", fileName);
                if (Files.exists(alternativePath)) {
                    filePath = alternativePath;
                } else {
                    System.err.println("Fichier météo non trouvé: " + fileName);
                    return data;
                }
            }

            try (BufferedReader reader = new BufferedReader(new FileReader(filePath.toFile()))) {
                String line = reader.readLine(); // Skip header
                if (line == null) {
                    return data;
                }

                int lineNumber = 1;
                while ((line = reader.readLine()) != null) {
                    lineNumber++;
                    try {
                        String[] parts = line.split(",");
                        if (parts.length < 3) {
                            continue;
                        }

                        // Parser datetime (peut être en format MM/dd/yyyy ou ISO)
                        LocalDateTime dateTime = parseDateTime(parts[0].trim());
                        if (dateTime == null) {
                            continue;
                        }

                        double temperature = Double.parseDouble(parts[1].trim());
                        double irradiance = Double.parseDouble(parts[2].trim());

                        // Arrondir à 6h pour la clé
                        LocalDateTime rounded = roundTo6Hours(dateTime);
                        data.put(rounded, new MeteoData(temperature, irradiance));
                    } catch (Exception e) {
                        // Ignorer les lignes invalides
                        System.err.println("Erreur ligne " + lineNumber + " dans " + fileName + ": " + e.getMessage());
                    }
                }
            }

            System.out.println("Fichier météo chargé: " + fileName + " (" + data.size() + " lignes)");
        } catch (IOException e) {
            System.err.println("Erreur lors du chargement du fichier météo " + fileName + ": " + e.getMessage());
        }

        return data;
    }

    /**
     * Parse un datetime depuis différents formats
     */
    private LocalDateTime parseDateTime(String dateTimeStr) {
        // Essayer différents formats
        DateTimeFormatter[] formatters = {
            DateTimeFormatter.ofPattern("M/d/yyyy"),
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"),
            DateTimeFormatter.ISO_DATE_TIME
        };

        for (DateTimeFormatter formatter : formatters) {
            try {
                return LocalDateTime.parse(dateTimeStr, formatter);
            } catch (DateTimeParseException e) {
                // Essayer le suivant
            }
        }

        return null;
    }

    /**
     * Arrondit un datetime à l'heure la plus proche multiple de 6
     */
    private LocalDateTime roundTo6Hours(LocalDateTime datetime) {
        int hour = datetime.getHour();
        int roundedHour = (hour / 6) * 6;
        return datetime.withHour(roundedHour).withMinute(0).withSecond(0).withNano(0);
    }

    /**
     * Trouve le datetime le plus proche dans un ensemble
     */
    private LocalDateTime findClosestDateTime(java.util.Set<LocalDateTime> dateTimes, LocalDateTime target) {
        if (dateTimes.isEmpty()) {
            return null;
        }

        LocalDateTime closest = null;
        long minDiff = Long.MAX_VALUE;

        for (LocalDateTime dt : dateTimes) {
            long diff = Math.abs(java.time.Duration.between(target, dt).toHours());
            if (diff < minDiff) {
                minDiff = diff;
                closest = dt;
            }
        }

        return closest;
    }

    /**
     * Vide le cache (utile pour recharger les données)
     */
    public void clearCache() {
        cache.clear();
    }
}



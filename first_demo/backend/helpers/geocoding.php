<?php
/**
 * Geocoding Helper — Google Geocoding API + OpenStreetMap Nominatim Fallback
 * 
 * Provides server-side geocoding and reverse-geocoding for address resolution.
 * Used by admin panel to geocode addresses when creating service areas.
 */

require_once __DIR__ . '/../config/database.php';

class GeocodingHelper {
    
    /** Google Geocoding API timeout in seconds */
    private const TIMEOUT = 5;
    
    /** Nominatim API base URL */
    private const NOMINATIM_URL = 'https://nominatim.openstreetmap.org';
    
    /**
     * Geocode an address string to lat/lng using Google Geocoding API.
     * Falls back to OpenStreetMap Nominatim if Google fails.
     *
     * @param string $address The address to geocode
     * @return array ['success' => bool, 'latitude' => float, 'longitude' => float, 
     *               'formatted_address' => string, 'country' => string, 'region' => string,
     *               'pincode' => string, 'city' => string, 'error' => string|null]
     */
    public static function geocodeAddress(string $address): array {
        // Try Google first
        $result = self::googleGeocode($address);
        if ($result['success']) return $result;
        
        // Fallback to Nominatim
        return self::nominatimGeocode($address);
    }
    
    /**
     * Reverse geocode coordinates to address.
     *
     * @param float $lat Latitude
     * @param float $lng Longitude
     * @return array Result matching geocodeAddress structure
     */
    public static function reverseGeocode(float $lat, float $lng): array {
        // Try Google first
        $result = self::googleReverseGeocode($lat, $lng);
        if ($result['success']) return $result;
        
        // Fallback to Nominatim
        return self::nominatimReverseGeocode($lat, $lng);
    }
    
    private static function googleGeocode(string $address): array {
        if (!defined('GOOGLE_MAPS_API_KEY')) {
            return ['success' => false, 'error' => 'Google Maps API Key not defined'];
        }
        
        $url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' . urlencode($address) . '&key=' . GOOGLE_MAPS_API_KEY;
        $response = self::curlGet($url);
        
        if (!$response['success']) {
            return ['success' => false, 'error' => $response['error']];
        }
        
        $data = json_decode($response['body'], true);
        if (!$data || !isset($data['status'])) {
            return ['success' => false, 'error' => 'Invalid JSON response from Google API'];
        }
        
        if ($data['status'] === 'OK' && !empty($data['results'])) {
            $result = $data['results'][0];
            $location = $result['geometry']['location'];
            
            $city = '';
            $region = '';
            $country = '';
            $pincode = '';
            
            foreach ($result['address_components'] as $component) {
                if (in_array('locality', $component['types'])) {
                    $city = $component['long_name'];
                }
                if (in_array('administrative_area_level_1', $component['types'])) {
                    $region = $component['long_name'];
                }
                if (in_array('country', $component['types'])) {
                    $country = $component['long_name'];
                }
                if (in_array('postal_code', $component['types'])) {
                    $pincode = $component['long_name'];
                }
            }
            
            return [
                'success' => true,
                'latitude' => (float)$location['lat'],
                'longitude' => (float)$location['lng'],
                'formatted_address' => $result['formatted_address'],
                'country' => $country,
                'region' => $region,
                'pincode' => $pincode,
                'city' => $city,
                'error' => null
            ];
        }
        
        return ['success' => false, 'error' => 'Google Geocode API Error: ' . $data['status']];
    }
    
    private static function nominatimGeocode(string $address): array {
        $url = self::NOMINATIM_URL . '/search?q=' . urlencode($address) . '&format=json&limit=1&addressdetails=1';
        $headers = ['User-Agent: GeocodingHelper/1.0 (jaywantmhala@gmail.com)'];
        
        $response = self::curlGet($url, $headers);
        
        if (!$response['success']) {
            return ['success' => false, 'error' => $response['error']];
        }
        
        $data = json_decode($response['body'], true);
        if (!$data) {
            return ['success' => false, 'error' => 'Invalid JSON response from Nominatim'];
        }
        
        if (empty($data)) {
            return ['success' => false, 'error' => 'Nominatim returned ZERO_RESULTS'];
        }
        
        $result = $data[0];
        $addressDetails = $result['address'] ?? [];
        
        return [
            'success' => true,
            'latitude' => (float) $result['lat'],
            'longitude' => (float) $result['lon'],
            'formatted_address' => $result['display_name'] ?? '',
            'country' => $addressDetails['country'] ?? '',
            'region' => $addressDetails['state'] ?? '',
            'pincode' => $addressDetails['postcode'] ?? '',
            'city' => $addressDetails['city'] ?? $addressDetails['town'] ?? $addressDetails['village'] ?? '',
            'error' => null
        ];
    }
    
    private static function googleReverseGeocode(float $lat, float $lng): array {
        if (!defined('GOOGLE_MAPS_API_KEY')) {
            return ['success' => false, 'error' => 'Google Maps API Key not defined'];
        }
        
        $url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' . $lat . ',' . $lng . '&key=' . GOOGLE_MAPS_API_KEY;
        $response = self::curlGet($url);
        
        if (!$response['success']) {
            return ['success' => false, 'error' => $response['error']];
        }
        
        $data = json_decode($response['body'], true);
        if (!$data || !isset($data['status'])) {
            return ['success' => false, 'error' => 'Invalid JSON response from Google'];
        }
        
        if ($data['status'] === 'OK' && !empty($data['results'])) {
            $result = $data['results'][0];
            
            $city = '';
            $region = '';
            $country = '';
            $pincode = '';
            
            foreach ($result['address_components'] as $component) {
                if (in_array('locality', $component['types'])) {
                    $city = $component['long_name'];
                }
                if (in_array('administrative_area_level_1', $component['types'])) {
                    $region = $component['long_name'];
                }
                if (in_array('country', $component['types'])) {
                    $country = $component['long_name'];
                }
                if (in_array('postal_code', $component['types'])) {
                    $pincode = $component['long_name'];
                }
            }
            
            return [
                'success' => true,
                'latitude' => $lat,
                'longitude' => $lng,
                'formatted_address' => $result['formatted_address'],
                'country' => $country,
                'region' => $region,
                'pincode' => $pincode,
                'city' => $city,
                'error' => null
            ];
        }
        
        return ['success' => false, 'error' => 'Google Reverse Geocode API Error: ' . $data['status']];
    }
    
    private static function nominatimReverseGeocode(float $lat, float $lng): array {
        $url = self::NOMINATIM_URL . '/reverse?lat=' . $lat . '&lon=' . $lng . '&format=json&addressdetails=1';
        $headers = ['User-Agent: GeocodingHelper/1.0 (jaywantmhala@gmail.com)'];
        
        $response = self::curlGet($url, $headers);
        
        if (!$response['success']) {
            return ['success' => false, 'error' => $response['error']];
        }
        
        $data = json_decode($response['body'], true);
        if (!$data || isset($data['error'])) {
            return ['success' => false, 'error' => $data['error'] ?? 'Invalid JSON response from Nominatim'];
        }
        
        $addressDetails = $data['address'] ?? [];
        
        return [
            'success' => true,
            'latitude' => $lat,
            'longitude' => $lng,
            'formatted_address' => $data['display_name'] ?? '',
            'country' => $addressDetails['country'] ?? '',
            'region' => $addressDetails['state'] ?? '',
            'pincode' => $addressDetails['postcode'] ?? '',
            'city' => $addressDetails['city'] ?? $addressDetails['town'] ?? $addressDetails['village'] ?? '',
            'error' => null
        ];
    }
    
    /**
     * Helper to make curl requests with timeout and error handling.
     */
    private static function curlGet(string $url, array $headers = []): array {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, self::TIMEOUT);
        
        if (!empty($headers)) {
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        }
        
        $response = curl_exec($ch);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($response === false) {
            return ['success' => false, 'body' => null, 'error' => 'cURL Error: ' . $error];
        }
        
        return ['success' => true, 'body' => $response, 'error' => null];
    }
}

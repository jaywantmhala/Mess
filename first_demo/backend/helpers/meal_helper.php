<?php
/**
 * meal_helper.php
 * Automatic Meal Type determination based on Asia/Kolkata server time.
 * 
 * Meal Timing Rules:
 * - Lunch:      06:00 AM (06:00) to 03:59 PM (15:59)
 * - Dinner:     04:00 PM (16:00) to 11:59 PM (23:59)
 * - Late Night: 12:00 AM (00:00) to 05:59 AM (05:59)
 */

if (!function_exists('getCurrentMealType')) {
    /**
     * Determines current meal type based on Asia/Kolkata server time.
     * 
     * @return string 'Lunch', 'Dinner', or 'Late Night'
     */
    function getCurrentMealType(): string {
        date_default_timezone_set('Asia/Kolkata');
        $currentHour = (int)date('H'); // 24-hour format: 0 to 23
        
        // Lunch: 06:00 AM (06:00) to 03:59 PM (15:59)
        if ($currentHour >= 6 && $currentHour <= 15) {
            return 'Lunch';
        }
        
        // Dinner: 04:00 PM (16:00) to 11:59 PM (23:59)
        if ($currentHour >= 16 && $currentHour <= 23) {
            return 'Dinner';
        }
        
        // Late Night: 12:00 AM (00:00) to 05:59 AM (05:59)
        return 'Dinner';
    }
}

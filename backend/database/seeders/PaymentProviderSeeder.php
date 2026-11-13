<?php

namespace Database\Seeders;

use App\Models\PaymentProvider;
use Illuminate\Database\Seeder;

class PaymentProviderSeeder extends Seeder
{
    public function run(): void
    {
        // Sama dengan PaymentOptions di Flutter.
        $ewallets = ['DANA', 'GoPay', 'OVO', 'ShopeePay', 'LinkAja'];
        $banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'BSI', 'CIMB Niaga', 'Permata', 'BTN', 'Danamon', 'Mega', 'Jatim'];

        foreach ($ewallets as $i => $name) {
            PaymentProvider::updateOrCreate(
                ['type' => 'ewallet', 'name' => $name],
                ['is_active' => true, 'sort_order' => $i + 1]
            );
        }

        foreach ($banks as $i => $name) {
            PaymentProvider::updateOrCreate(
                ['type' => 'bank', 'name' => $name],
                ['is_active' => true, 'sort_order' => $i + 1]
            );
        }
    }
}

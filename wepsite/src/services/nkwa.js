import { environment } from '../config/environment';

export const PaymentStatus = {
    PENDING: 'pending',
    SUCCESS: 'success',
    FAILED: 'failed',
    CANCELLED: 'cancelled'
};

export const nkwaService = {
    getDepartmentCreationFee() {
        return environment.nkwa.departmentCreationFee;
    },

    getCurrency() {
        return environment.nkwa.currency;
    },

    isValidPhoneNumber(phone) {
        const phoneRegex = /^237[0-9]{9}$/;
        return phoneRegex.test(phone.replace(/\s+/g, ''));
    },

    formatPhoneNumber(phone) {
        const cleaned = phone.replace(/\s+/g, '');
        if (cleaned.startsWith('237')) return cleaned;
        if (cleaned.startsWith('6') || cleaned.startsWith('2')) return '237' + cleaned;
        return cleaned;
    },

    generatePaymentRef() {
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 10000);
        return `DEPT_${timestamp}_${random}`;
    },

    async collectPayment(amount, phoneNumber, description) {
        const response = await fetch(`${environment.nkwa.baseUrl}/v1/payment/collect`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${environment.nkwa.apiKey}`
            },
            body: JSON.stringify({
                amount,
                phone: phoneNumber,
                description,
                currency: this.getCurrency()
            })
        });

        if (!response.ok) {
            throw new Error(`Payment failed: ${response.statusText}`);
        }

        return await response.json();
    },

    async checkPaymentStatus(paymentId) {
        const response = await fetch(`${environment.nkwa.baseUrl}/v1/payment/${paymentId}`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${environment.nkwa.apiKey}`
            }
        });

        if (!response.ok) {
            throw new Error(`Status check failed: ${response.statusText}`);
        }

        const data = await response.json();

        switch (data.status?.toLowerCase()) {
            case 'successful':
            case 'success':
            case 'completed':
                return PaymentStatus.SUCCESS;
            case 'failed':
            case 'error':
                return PaymentStatus.FAILED;
            case 'cancelled':
            case 'canceled':
                return PaymentStatus.CANCELLED;
            default:
                return PaymentStatus.PENDING;
        }
    }
};

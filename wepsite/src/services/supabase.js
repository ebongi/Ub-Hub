import { createClient } from '@supabase/supabase-js';
import { environment } from '../config/environment';

const supabase = createClient(
    environment.supabase.url,
    environment.supabase.anonKey
);

export const supabaseService = {
    // Auth methods
    async signUp(email, password, metadata = {}) {
        const { data, error } = await supabase.auth.signUp({
            email,
            password,
            options: { data: metadata }
        });
        if (error) throw error;
        return data;
    },

    async signIn(email, password) {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });
        if (error) throw error;
        return data;
    },

    async signOut() {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
    },

    getCurrentUser() {
        return supabase.auth.getUser();
    },

    onAuthStateChange(callback) {
        return supabase.auth.onAuthStateChange(callback);
    },

    // Database methods
    async getDepartments() {
        const { data, error } = await supabase
            .from('departments')
            .select('*')
            .order('created_at', { ascending: false });
        if (error) throw error;
        return data;
    },

    async createDepartment(department) {
        const { data, error } = await supabase
            .from('departments')
            .insert(department)
            .select()
            .single();
        if (error) throw error;
        return data;
    },

    async uploadFile(bucket, path, file) {
        const { error } = await supabase.storage
            .from(bucket)
            .upload(path, file);
        if (error) throw error;

        const { data: { publicUrl } } = supabase.storage
            .from(bucket)
            .getPublicUrl(path);

        return publicUrl;
    },

    async createPaymentTransaction(transaction) {
        const { data, error } = await supabase
            .from('payment_transactions')
            .insert(transaction)
            .select()
            .single();
        if (error) throw error;
        return data;
    },

    async updatePaymentStatus(paymentRef, status, departmentId) {
        const updateData = { status, updated_at: new Date().toISOString() };
        if (departmentId) {
            updateData.department_id = departmentId;
        }

        const { data, error } = await supabase
            .from('payment_transactions')
            .update(updateData)
            .eq('payment_ref', paymentRef)
            .select()
            .single();
        if (error) throw error;
        return data;
    },

    getClient() {
        return supabase;
    }
};

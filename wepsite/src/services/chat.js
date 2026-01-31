import { supabaseService } from './supabase';

const supabase = supabaseService.getClient();

export const chatService = {
    async getMessages() {
        const { data, error } = await supabase
            .from('messages')
            .select('*')
            .order('created_at', { ascending: true })
            .limit(100);

        if (error) throw error;
        return data;
    },

    subscribeToMessages(callback) {
        return supabase
            .channel('public:messages')
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'messages'
                },
                (payload) => {
                    callback(payload.new);
                }
            )
            .subscribe();
    },

    unsubscribe(subscription) {
        if (subscription) {
            supabase.removeChannel(subscription);
        }
    },

    async sendMessage(content) {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('User not authenticated');

        const { data, error } = await supabase
            .from('messages')
            .insert({
                user_id: user.id,
                user_email: user.email,
                content,
                created_at: new Date().toISOString()
            })
            .select()
            .single();

        if (error) throw error;
        return data;
    }
};

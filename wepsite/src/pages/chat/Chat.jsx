import { useState, useEffect, useRef } from 'react';
import { chatService } from '../../services/chat';
import { supabaseService } from '../../services/supabase';
import './Chat.css';

export default function Chat() {
    const [messages, setMessages] = useState([]);
    const [newMessage, setNewMessage] = useState('');
    const [currentUser, setCurrentUser] = useState(null);
    const messagesEndRef = useRef(null);
    const subscriptionRef = useRef(null);

    useEffect(() => {
        // Get current user
        supabaseService.getCurrentUser().then(({ data }) => {
            setCurrentUser(data.user);
        });

        // Load initial messages
        loadMessages();

        // Subscribe to new messages
        subscriptionRef.current = chatService.subscribeToMessages((message) => {
            setMessages(prev => [...prev, message]);
        });

        return () => {
            if (subscriptionRef.current) {
                chatService.unsubscribe(subscriptionRef.current);
            }
        };
    }, []);

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const loadMessages = async () => {
        try {
            const data = await chatService.getMessages();
            setMessages(data || []);
        } catch (error) {
            console.error('Error loading messages:', error);
        }
    };

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    const handleSendMessage = async (e) => {
        e.preventDefault();
        if (!newMessage.trim()) return;

        try {
            await chatService.sendMessage(newMessage);
            setNewMessage('');
        } catch (error) {
            console.error('Error sending message:', error);
            alert('Failed to send message: ' + error.message);
        }
    };

    return (
        <div className="chat-container">
            <div className="chat-header">
                <h1>Global Campus Chat</h1>
            </div>

            <div className="messages-area">
                {messages.length === 0 ? (
                    <div className="empty-chat">
                        <p>No messages yet. Be the first to say hello!</p>
                    </div>
                ) : (
                    messages.map((msg) => {
                        const isOwn = currentUser && msg.user_id === currentUser.id;
                        return (
                            <div key={msg.id} className={`message-bubble ${isOwn ? 'own-message' : 'other-message'}`}>
                                <div className="message-info">
                                    <span className="user-email">{msg.user_email?.split('@')[0]}</span>
                                    <span className="timestamp">{new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                </div>
                                <div className="message-content">
                                    {msg.content}
                                </div>
                            </div>
                        );
                    })
                )}
                <div ref={messagesEndRef} />
            </div>

            <form className="message-input-area" onSubmit={handleSendMessage}>
                <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Type a message..."
                    disabled={!currentUser}
                />
                <button type="submit" disabled={!newMessage.trim() || !currentUser}>
                    Send
                </button>
            </form>
        </div>
    );
}

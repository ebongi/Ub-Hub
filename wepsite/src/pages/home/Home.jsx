import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabaseService } from '../../services/supabase';
import './Home.css';

const features = [
    { title: 'Departments', icon: '🏛️', route: '/departments', color: '#00E5FF' },
    { title: 'Global Chat', icon: '💬', route: '/chat', color: '#00B8D4' },
    { title: 'AI Assistant', icon: '🤖', route: '/ai-assistant', color: '#0097A7' },
    { title: 'GPA Calculator', icon: '📊', route: '/gpa', color: '#00838F' },
    { title: 'Focus Timer', icon: '⏱️', route: '/timer', color: '#006064' },
    { title: 'Task Manager', icon: '✅', route: '/tasks', color: '#004D40' },
    { title: 'Exam Schedule', icon: '📅', route: '/exams', color: '#00695C' },
    { title: 'Flashcards', icon: '🃏', route: '/flashcards', color: '#00796B' }
];

export default function Home() {
    const [userName, setUserName] = useState('Student');
    const navigate = useNavigate();

    useEffect(() => {
        supabaseService.getCurrentUser().then(({ data }) => {
            if (data.user) {
                setUserName(data.user.email?.split('@')[0] || 'Student');
            }
        });
    }, []);

    const handleLogout = async () => {
        await supabaseService.signOut();
        navigate('/login');
    };

    return (
        <div className="home-container">
            <nav className="navbar">
                <div className="nav-content">
                    <h1 className="logo">Ub Studies</h1>
                    <div className="nav-actions">
                        <span className="user-name">Welcome, {userName}</span>
                        <button className="btn-logout" onClick={handleLogout}>Logout</button>
                    </div>
                </div>
            </nav>

            <div className="hero-section">
                <h2 className="hero-title">Your Academic Hub</h2>
                <p className="hero-subtitle">Everything you need for academic success, all in one place</p>
            </div>

            <div className="features-grid">
                {features.map((feature) => (
                    <Link
                        key={feature.route}
                        to={feature.route}
                        className="feature-card"
                        style={{ '--card-color': feature.color }}
                    >
                        <div className="feature-icon">{feature.icon}</div>
                        <h3 className="feature-title">{feature.title}</h3>
                        <div className="feature-arrow">→</div>
                    </Link>
                ))}
            </div>
        </div>
    );
}

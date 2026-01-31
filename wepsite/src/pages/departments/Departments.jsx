import { useState, useEffect } from 'react';
import { supabaseService } from '../../services/supabase';
import { nkwaService, PaymentStatus } from '../../services/nkwa';
import './Departments.css';

export default function Departments() {
    const [departments, setDepartments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showAddModal, setShowAddModal] = useState(false);
    const [showPaymentModal, setShowPaymentModal] = useState(false);

    // Form State
    const [formData, setFormData] = useState({
        name: '',
        schoolId: '',
        description: '',
        phoneNumber: '',
    });
    const [selectedImage, setSelectedImage] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);

    // Payment State
    const [paymentStatus, setPaymentStatus] = useState({
        message: '',
        processing: false
    });

    const creationFee = nkwaService.getDepartmentCreationFee();
    const currency = nkwaService.getCurrency();

    useEffect(() => {
        loadDepartments();
    }, []);

    const loadDepartments = async () => {
        try {
            const data = await supabaseService.getDepartments();
            setDepartments(data || []);
        } catch (error) {
            console.error('Error loading departments:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleImageSelect = (e) => {
        const file = e.target.files[0];
        if (file) {
            setSelectedImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    const resetForm = () => {
        setFormData({
            name: '',
            schoolId: '',
            description: '',
            phoneNumber: ''
        });
        setSelectedImage(null);
        setImagePreview(null);
        setShowAddModal(false);
        setShowPaymentModal(false);
        setPaymentStatus({ message: '', processing: false });
    };

    const pollPaymentStatus = async (paymentId) => {
        const maxAttempts = 60; // 2 minutes
        let attempts = 0;

        while (attempts < maxAttempts) {
            try {
                const status = await nkwaService.checkPaymentStatus(paymentId);

                if (status === PaymentStatus.SUCCESS) {
                    return true;
                } else if (status === PaymentStatus.FAILED || status === PaymentStatus.CANCELLED) {
                    return false;
                }

                await new Promise(resolve => setTimeout(resolve, 2000));
                attempts++;
            } catch (error) {
                console.error('Error polling payment status:', error);
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        }
        return false;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!nkwaService.isValidPhoneNumber(formData.phoneNumber)) {
            alert('Invalid phone number format. Please use 237XXXXXXXXX');
            return;
        }

        if (!selectedImage) {
            alert('Please select a department image');
            return;
        }

        setShowAddModal(false);
        setShowPaymentModal(true);
        setPaymentStatus({ processing: true, message: 'Initiating payment...' });

        try {
            const currentUser = await supabaseService.getCurrentUser();
            if (!currentUser.data.user) throw new Error('User not authenticated');

            const formattedPhone = nkwaService.formatPhoneNumber(formData.phoneNumber);
            const paymentRef = nkwaService.generatePaymentRef();

            // Record transaction
            await supabaseService.createPaymentTransaction({
                user_id: currentUser.data.user.id,
                payment_ref: paymentRef,
                amount: creationFee,
                currency: currency,
                status: 'pending',
                created_at: new Date().toISOString()
            });

            // Collect Payment
            const paymentResponse = await nkwaService.collectPayment(
                creationFee,
                formattedPhone,
                `Dept: ${formData.name}`
            );

            setPaymentStatus({ processing: true, message: 'Please confirm payment on your phone...' });

            // Poll Status
            const success = await pollPaymentStatus(paymentResponse.id);

            if (success) {
                setPaymentStatus({ processing: true, message: 'Payment successful! Creating department...' });

                // Upload Image
                const imagePath = `departments/${Date.now()}_${selectedImage.name}`;
                const imageUrl = await supabaseService.uploadFile('departments', imagePath, selectedImage);

                // Create Department
                const newDept = await supabaseService.createDepartment({
                    name: formData.name,
                    school_id: formData.schoolId,
                    description: formData.description,
                    image_url: imageUrl,
                    created_at: new Date().toISOString()
                });

                // Update Transaction
                await supabaseService.updatePaymentStatus(paymentRef, 'success', newDept.id);

                setPaymentStatus({ processing: false, message: 'Department created successfully!' });
                setTimeout(() => {
                    resetForm();
                    loadDepartments();
                }, 2000);
            } else {
                setPaymentStatus({ processing: false, message: 'Payment failed or cancelled.' });
                await supabaseService.updatePaymentStatus(paymentRef, 'failed');
                setTimeout(() => setShowPaymentModal(false), 3000);
            }

        } catch (error) {
            console.error('Process error:', error);
            setPaymentStatus({ processing: false, message: `Error: ${error.message}` });
            setTimeout(() => setShowPaymentModal(false), 3000);
        }
    };

    return (
        <div className="departments-container">
            <div className="header">
                <h1>Departments</h1>
                <button className="btn-add" onClick={() => setShowAddModal(true)}>+ Add Department</button>
            </div>

            {loading ? (
                <div className="loading">Loading departments...</div>
            ) : departments.length === 0 ? (
                <div className="empty-state">
                    <p>No departments yet. Create one to get started!</p>
                </div>
            ) : (
                <div className="departments-grid">
                    {departments.map(dept => (
                        <div key={dept.id} className="department-card">
                            {dept.image_url ? (
                                <img src={dept.image_url} alt={dept.name} className="dept-image" />
                            ) : (
                                <div className="dept-image-placeholder">🏛️</div>
                            )}
                            <div className="dept-content">
                                <h3>{dept.name}</h3>
                                <p className="school-id">{dept.school_id}</p>
                                <p className="description">{dept.description}</p>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Add Modal */}
            {showAddModal && (
                <div className="modal-overlay" onClick={resetForm}>
                    <div className="modal-content" onClick={e => e.stopPropagation()}>
                        <h2>Add Department</h2>
                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label>Department Name</label>
                                <input
                                    type="text"
                                    name="name"
                                    value={formData.name}
                                    onChange={handleInputChange}
                                    required
                                />
                            </div>

                            <div className="form-group">
                                <label>School ID</label>
                                <input
                                    type="text"
                                    name="schoolId"
                                    value={formData.schoolId}
                                    onChange={handleInputChange}
                                    required
                                />
                            </div>

                            <div className="form-group">
                                <label>Description</label>
                                <textarea
                                    name="description"
                                    rows="3"
                                    value={formData.description}
                                    onChange={handleInputChange}
                                    required
                                />
                            </div>

                            <div className="form-group">
                                <label>Phone Number (for payment)</label>
                                <input
                                    type="tel"
                                    name="phoneNumber"
                                    placeholder="237XXXXXXXXX"
                                    value={formData.phoneNumber}
                                    onChange={handleInputChange}
                                    required
                                />
                            </div>

                            <div className="fee-info">
                                Fee: {creationFee} {currency}
                            </div>

                            <div className="form-group">
                                <label>Image</label>
                                <input type="file" accept="image/*" onChange={handleImageSelect} required />
                                {imagePreview && <img src={imagePreview} alt="Preview" className="image-preview" />}
                            </div>

                            <div className="modal-actions">
                                <button type="button" className="btn-cancel" onClick={resetForm}>Cancel</button>
                                <button type="submit" className="btn-submit">Create & Pay</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Payment Modal */}
            {showPaymentModal && (
                <div className="modal-overlay">
                    <div className="modal-content payment-modal">
                        <h2>Payment Status</h2>
                        <div className="payment-status">
                            {paymentStatus.processing && <div className="spinner-large"></div>}
                            <p>{paymentStatus.message}</p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

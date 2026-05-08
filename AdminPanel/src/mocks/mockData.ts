import type { Claim, User, Conversation, DashboardStats, ClaimsTrendData } from '../types';

export const mockDashboardStats: DashboardStats = {
  totalClaims: 1248,
  pendingClaims: 156,
  approvedClaims: 892,
  rejectedClaims: 200,
  totalUsers: 3420,
  activeConversations: 24,
  claimsToday: 18,
  avgResolutionDays: 4.2,
};

export const mockClaims: Claim[] = [
  { id: '1', claimNumber: 'CLM-77129-AZ', userId: '1', userName: 'David Smith', type: 'Accident', status: 'InReview', vehicleReg: 'MH 12 AB 3456', incidentDate: '2026-01-12', submittedAt: '2026-01-13', updatedAt: '2026-01-15', photos: ['/photos/1a.jpg', '/photos/1b.jpg'], claimantType: 'Policy Holder', amount: 45000 },
  { id: '2', claimNumber: 'CLM-77130-TX', userId: '2', userName: 'Sarah Johnson', type: 'Theft', status: 'Pending', vehicleReg: 'DL 05 CD 7890', incidentDate: '2026-01-15', submittedAt: '2026-01-16', updatedAt: '2026-01-16', photos: ['/photos/2a.jpg'], claimantType: 'Policy Holder', amount: 320000 },
  { id: '3', claimNumber: 'CLM-77131-CA', userId: '3', userName: 'Mike Brown', type: 'Natural Disaster', status: 'Approved', vehicleReg: 'KA 01 EF 1234', incidentDate: '2026-01-10', submittedAt: '2026-01-11', updatedAt: '2026-01-14', photos: ['/photos/3a.jpg', '/photos/3b.jpg', '/photos/3c.jpg'], claimantType: 'Policy Holder', amount: 125000 },
  { id: '4', claimNumber: 'CLM-77132-NY', userId: '4', userName: 'Emily Davis', type: 'Vandalism', status: 'Rejected', vehicleReg: 'TN 09 GH 5678', incidentDate: '2026-01-08', submittedAt: '2026-01-09', updatedAt: '2026-01-12', photos: ['/photos/4a.jpg'], claimantType: 'Policy Holder', amount: 18000 },
  { id: '5', claimNumber: 'CLM-77133-FL', userId: '5', userName: 'James Wilson', type: 'Accident', status: 'Approved', vehicleReg: 'GJ 06 IJ 9012', incidentDate: '2026-01-20', submittedAt: '2026-01-21', updatedAt: '2026-01-25', photos: ['/photos/5a.jpg', '/photos/5b.jpg'], claimantType: 'Third-party', amount: 67000 },
  { id: '6', claimNumber: 'CLM-77134-WA', userId: '6', userName: 'Olivia Martinez', type: 'Theft', status: 'Pending', vehicleReg: 'RJ 14 KL 3456', incidentDate: '2026-02-01', submittedAt: '2026-02-02', updatedAt: '2026-02-02', photos: [], claimantType: 'Policy Holder', amount: 25000 },
  { id: '7', claimNumber: 'CLM-77135-IL', userId: '7', userName: 'William Taylor', type: 'Accident', status: 'InReview', vehicleReg: 'UP 32 MN 7890', incidentDate: '2026-02-05', submittedAt: '2026-02-06', updatedAt: '2026-02-08', photos: ['/photos/7a.jpg', '/photos/7b.jpg'], claimantType: 'Policy Holder', amount: 95000 },
  { id: '8', claimNumber: 'CLM-77136-OH', userId: '8', userName: 'Sophia Anderson', type: 'Natural Disaster', status: 'Approved', vehicleReg: 'MP 04 OP 1234', incidentDate: '2026-02-10', submittedAt: '2026-02-11', updatedAt: '2026-02-15', photos: ['/photos/8a.jpg'], claimantType: 'Policy Holder', amount: 42000 },
  { id: '9', claimNumber: 'CLM-77137-GA', userId: '9', userName: 'Alexander Thomas', type: 'Vandalism', status: 'Pending', vehicleReg: 'HR 26 QR 5678', incidentDate: '2026-02-12', submittedAt: '2026-02-13', updatedAt: '2026-02-13', photos: ['/photos/9a.jpg'], claimantType: 'Policy Holder', amount: 15000 },
  { id: '10', claimNumber: 'CLM-77138-NC', userId: '10', userName: 'Isabella Jackson', type: 'Accident', status: 'Rejected', vehicleReg: 'WB 06 ST 9012', incidentDate: '2026-02-18', submittedAt: '2026-02-19', updatedAt: '2026-02-22', photos: [], claimantType: 'Third-party', amount: 12000 },
  { id: '11', claimNumber: 'CLM-77139-MI', userId: '1', userName: 'David Smith', type: 'Theft', status: 'Approved', vehicleReg: 'MH 12 AB 3456', incidentDate: '2026-03-01', submittedAt: '2026-03-02', updatedAt: '2026-03-05', photos: ['/photos/11a.jpg'], claimantType: 'Policy Holder', amount: 55000 },
  { id: '12', claimNumber: 'CLM-77140-PA', userId: '2', userName: 'Sarah Johnson', type: 'Accident', status: 'Pending', vehicleReg: 'DL 05 CD 7890', incidentDate: '2026-03-05', submittedAt: '2026-03-06', updatedAt: '2026-03-06', photos: ['/photos/12a.jpg'], claimantType: 'Policy Holder', amount: 22000 },
  { id: '13', claimNumber: 'CLM-77141-NJ', userId: '3', userName: 'Mike Brown', type: 'Natural Disaster', status: 'InReview', vehicleReg: 'KA 01 EF 1234', incidentDate: '2026-03-10', submittedAt: '2026-03-11', updatedAt: '2026-03-13', photos: ['/photos/13a.jpg', '/photos/13b.jpg'], claimantType: 'Policy Holder', amount: 180000 },
  { id: '14', claimNumber: 'CLM-77142-VA', userId: '4', userName: 'Emily Davis', type: 'Accident', status: 'Approved', vehicleReg: 'TN 09 GH 5678', incidentDate: '2026-03-15', submittedAt: '2026-03-16', updatedAt: '2026-03-20', photos: ['/photos/14a.jpg'], claimantType: 'Third-party', amount: 78000 },
  { id: '15', claimNumber: 'CLM-77143-MA', userId: '5', userName: 'James Wilson', type: 'Vandalism', status: 'Pending', vehicleReg: 'GJ 06 IJ 9012', incidentDate: '2026-03-20', submittedAt: '2026-03-21', updatedAt: '2026-03-21', photos: ['/photos/15a.jpg'], claimantType: 'Policy Holder', amount: 20000 },
  { id: '16', claimNumber: 'CLM-77144-AZ', userId: '6', userName: 'Olivia Martinez', type: 'Accident', status: 'Approved', vehicleReg: 'RJ 14 KL 3456', incidentDate: '2026-03-25', submittedAt: '2026-03-26', updatedAt: '2026-03-30', photos: ['/photos/16a.jpg', '/photos/16b.jpg'], claimantType: 'Policy Holder', amount: 150000 },
  { id: '17', claimNumber: 'CLM-77145-TX', userId: '7', userName: 'William Taylor', type: 'Theft', status: 'Rejected', vehicleReg: 'UP 32 MN 7890', incidentDate: '2026-04-01', submittedAt: '2026-04-02', updatedAt: '2026-04-05', photos: [], claimantType: 'Policy Holder', amount: 280000 },
  { id: '18', claimNumber: 'CLM-77146-CA', userId: '8', userName: 'Sophia Anderson', type: 'Natural Disaster', status: 'Pending', vehicleReg: 'MP 04 OP 1234', incidentDate: '2026-04-05', submittedAt: '2026-04-06', updatedAt: '2026-04-06', photos: ['/photos/18a.jpg'], claimantType: 'Policy Holder', amount: 35000 },
  { id: '19', claimNumber: 'CLM-77147-NY', userId: '9', userName: 'Alexander Thomas', type: 'Accident', status: 'InReview', vehicleReg: 'HR 26 QR 5678', incidentDate: '2026-04-10', submittedAt: '2026-04-11', updatedAt: '2026-04-13', photos: ['/photos/19a.jpg', '/photos/19b.jpg', '/photos/19c.jpg'], claimantType: 'Policy Holder', amount: 210000 },
  { id: '20', claimNumber: 'CLM-77148-FL', userId: '10', userName: 'Isabella Jackson', type: 'Vandalism', status: 'Approved', vehicleReg: 'WB 06 ST 9012', incidentDate: '2026-04-12', submittedAt: '2026-04-13', updatedAt: '2026-04-16', photos: ['/photos/20a.jpg'], claimantType: 'Policy Holder', amount: 30000 },
];

export const mockUsers: User[] = [
  { id: '1', name: 'David Smith', email: 'david.smith@email.com', phone: '+91 98765 43210', country: 'India', avatarPersonality: 'Professional', memberSince: '2024-06-15', totalClaims: 3, status: 'Active', profileImage: '' },
  { id: '2', name: 'Sarah Johnson', email: 'sarah.j@email.com', phone: '+91 87654 32109', country: 'India', avatarPersonality: 'Friendly', memberSince: '2024-08-20', totalClaims: 2, status: 'Active' },
  { id: '3', name: 'Mike Brown', email: 'mike.brown@email.com', phone: '+91 76543 21098', country: 'India', avatarPersonality: 'Smart', memberSince: '2024-09-10', totalClaims: 2, status: 'Active' },
  { id: '4', name: 'Emily Davis', email: 'emily.d@email.com', phone: '+91 65432 10987', country: 'India', avatarPersonality: 'Professional', memberSince: '2024-10-01', totalClaims: 2, status: 'Active' },
  { id: '5', name: 'James Wilson', email: 'james.w@email.com', phone: '+91 54321 09876', country: 'India', avatarPersonality: 'Friendly', memberSince: '2024-11-15', totalClaims: 2, status: 'Active' },
  { id: '6', name: 'Olivia Martinez', email: 'olivia.m@email.com', phone: '+1 555 123 4567', country: 'USA', avatarPersonality: 'Smart', memberSince: '2025-01-05', totalClaims: 2, status: 'Active' },
  { id: '7', name: 'William Taylor', email: 'will.t@email.com', phone: '+1 555 234 5678', country: 'USA', avatarPersonality: 'Professional', memberSince: '2025-02-14', totalClaims: 2, status: 'Suspended' },
  { id: '8', name: 'Sophia Anderson', email: 'sophia.a@email.com', phone: '+44 7700 900123', country: 'UK', avatarPersonality: 'Friendly', memberSince: '2025-03-20', totalClaims: 2, status: 'Active' },
  { id: '9', name: 'Alexander Thomas', email: 'alex.t@email.com', phone: '+61 4 1234 5678', country: 'Australia', avatarPersonality: 'Smart', memberSince: '2025-04-10', totalClaims: 2, status: 'Active' },
  { id: '10', name: 'Isabella Jackson', email: 'bella.j@email.com', phone: '+91 43210 98765', country: 'India', avatarPersonality: 'Professional', memberSince: '2025-05-01', totalClaims: 2, status: 'Active' },
];

export const mockConversations: Conversation[] = [
  { id: '1', threadId: 'THR-001', userId: '1', userName: 'David Smith', mode: 'Chat', startedAt: '2026-04-15T09:30:00Z', endedAt: '2026-04-15T09:37:00Z', duration: 420, messageCount: 12, claimId: '1', status: 'Completed', chatJsonPath: '/uploads/transcripts/THR-001.json', messages: [
    { id: 'm1', type: 'bot', content: 'Hello! I\'m your ClaimAI assistant. How can I help you today?', timestamp: '2026-04-15T09:30:00Z', suggestions: ['File a new claim', 'Check claim status', 'Talk to an agent'] },
    { id: 'm2', type: 'user', content: 'I want to file a new claim for a car accident', timestamp: '2026-04-15T09:30:30Z' },
    { id: 'm3', type: 'bot', content: 'I\'m sorry to hear about the accident. Let me help you file a claim. First, are you the policy holder or a third-party claimant?', timestamp: '2026-04-15T09:30:45Z', suggestions: ['Policy Holder', 'Third-party'] },
    { id: 'm4', type: 'user', content: 'Policy Holder', timestamp: '2026-04-15T09:31:00Z' },
    { id: 'm5', type: 'bot', content: 'Thank you. What is your vehicle registration number?', timestamp: '2026-04-15T09:31:15Z' },
    { id: 'm6', type: 'user', content: 'MH 12 AB 3456', timestamp: '2026-04-15T09:31:30Z' },
    { id: 'm7', type: 'bot', content: 'Got it. When did the incident occur?', timestamp: '2026-04-15T09:31:45Z' },
    { id: 'm8', type: 'user', content: 'January 12th, 2026', timestamp: '2026-04-15T09:32:00Z' },
    { id: 'm9', type: 'bot', content: 'Please describe what happened in the accident.', timestamp: '2026-04-15T09:32:15Z' },
    { id: 'm10', type: 'user', content: 'Rear-end collision at traffic signal. Bumper and tail lights damaged.', timestamp: '2026-04-15T09:33:00Z' },
    { id: 'm11', type: 'bot', content: 'Thank you for the details. Would you like to upload any photos of the damage?', timestamp: '2026-04-15T09:33:15Z', suggestions: ['Upload photos', 'Skip for now'] },
    { id: 'm12', type: 'user', content: 'I\'ll upload photos now', timestamp: '2026-04-15T09:33:30Z' },
  ] },
  { id: '2', threadId: 'THR-002', userId: '2', userName: 'Sarah Johnson', mode: 'Voice', startedAt: '2026-04-15T10:00:00Z', endedAt: '2026-04-15T10:05:00Z', duration: 300, messageCount: 8, status: 'Completed', chatJsonPath: '/uploads/transcripts/THR-002.json', messages: [
    { id: 'm1', type: 'bot', content: 'Welcome to ClaimAI voice assistant. How may I assist you?', timestamp: '2026-04-15T10:00:00Z' },
    { id: 'm2', type: 'user', content: 'I want to check the status of my theft claim', timestamp: '2026-04-15T10:00:15Z' },
    { id: 'm3', type: 'bot', content: 'I can help with that. Your claim CLM-77130-TX is currently in Pending status. It was submitted on January 16th.', timestamp: '2026-04-15T10:00:30Z' },
    { id: 'm4', type: 'user', content: 'When will it be reviewed?', timestamp: '2026-04-15T10:00:45Z' },
    { id: 'm5', type: 'bot', content: 'Theft claims typically take 5-7 business days for initial review. Your claim should be reviewed within the next 3 days.', timestamp: '2026-04-15T10:01:00Z' },
  ] },
  { id: '3', threadId: 'THR-003', userId: '3', userName: 'Mike Brown', mode: 'Chat', startedAt: '2026-04-14T14:20:00Z', endedAt: '2026-04-14T14:23:00Z', duration: 180, messageCount: 6, claimId: '3', status: 'Completed', chatJsonPath: '/uploads/transcripts/THR-003.json', messages: [
    { id: 'm1', type: 'bot', content: 'Hi! How can I help you today?', timestamp: '2026-04-14T14:20:00Z' },
    { id: 'm2', type: 'user', content: 'My flood damage claim was approved. When do I get the payment?', timestamp: '2026-04-14T14:20:20Z' },
    { id: 'm3', type: 'bot', content: 'Congratulations! Your claim CLM-77131-CA has been approved for â‚¹1,25,000. Payment will be processed within 5 business days.', timestamp: '2026-04-14T14:20:35Z' },
  ] },
  { id: '4', threadId: 'THR-004', userId: '4', userName: 'Emily Davis', mode: 'Chat', startedAt: '2026-04-14T11:00:00Z', duration: 240, messageCount: 10, claimId: '4', status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Hello! I\'m here to help. What would you like to do?', timestamp: '2026-04-14T11:00:00Z' },
    { id: 'm2', type: 'user', content: 'Why was my vandalism claim rejected?', timestamp: '2026-04-14T11:00:15Z' },
    { id: 'm3', type: 'bot', content: 'I\'m sorry about that. Let me check your claim CLM-77132-NY. It was rejected due to insufficient evidence. The photos provided did not clearly show vandalism damage.', timestamp: '2026-04-14T11:00:30Z' },
  ] },
  { id: '5', threadId: 'THR-005', userId: '5', userName: 'James Wilson', mode: 'Voice', startedAt: '2026-04-13T16:45:00Z', duration: 600, messageCount: 15, claimId: '5', status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Welcome! How can I assist you?', timestamp: '2026-04-13T16:45:00Z' },
    { id: 'm2', type: 'user', content: 'I need to file a third-party claim for a side collision', timestamp: '2026-04-13T16:45:15Z' },
  ] },
  { id: '6', threadId: 'THR-006', userId: '6', userName: 'Olivia Martinez', mode: 'Chat', startedAt: '2026-04-16T08:00:00Z', duration: 120, messageCount: 4, status: 'Active', messages: [
    { id: 'm1', type: 'bot', content: 'Good morning! How can I help you today?', timestamp: '2026-04-16T08:00:00Z' },
    { id: 'm2', type: 'user', content: 'I want to know about my claim status', timestamp: '2026-04-16T08:00:20Z' },
  ] },
  { id: '7', threadId: 'THR-007', userId: '7', userName: 'William Taylor', mode: 'Voice', startedAt: '2026-04-16T09:15:00Z', duration: 90, messageCount: 3, status: 'Abandoned', messages: [
    { id: 'm1', type: 'bot', content: 'Hello! Welcome to ClaimAI.', timestamp: '2026-04-16T09:15:00Z' },
    { id: 'm2', type: 'user', content: 'I need help with...', timestamp: '2026-04-16T09:15:30Z' },
  ] },
  { id: '8', threadId: 'THR-008', userId: '8', userName: 'Sophia Anderson', mode: 'Chat', startedAt: '2026-04-16T10:30:00Z', duration: 360, messageCount: 9, claimId: '18', status: 'Active', messages: [
    { id: 'm1', type: 'bot', content: 'Hi there! How can I assist you?', timestamp: '2026-04-16T10:30:00Z' },
    { id: 'm2', type: 'user', content: 'I want to file a claim for lightning damage to my car', timestamp: '2026-04-16T10:30:20Z' },
    { id: 'm3', type: 'bot', content: 'I can help with that. Let\'s start with your details.', timestamp: '2026-04-16T10:30:35Z' },
  ] },
  { id: '9', threadId: 'THR-009', userId: '9', userName: 'Alexander Thomas', mode: 'Chat', startedAt: '2026-04-15T13:00:00Z', duration: 480, messageCount: 14, claimId: '19', status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Hello! What can I do for you?', timestamp: '2026-04-15T13:00:00Z' },
    { id: 'm2', type: 'user', content: 'Filing a claim for rollover accident', timestamp: '2026-04-15T13:00:15Z' },
  ] },
  { id: '10', threadId: 'THR-010', userId: '10', userName: 'Isabella Jackson', mode: 'Voice', startedAt: '2026-04-15T15:30:00Z', duration: 200, messageCount: 7, claimId: '20', status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Welcome to ClaimAI. How may I help?', timestamp: '2026-04-15T15:30:00Z' },
    { id: 'm2', type: 'user', content: 'I need to report vandalism on my car', timestamp: '2026-04-15T15:30:10Z' },
  ] },
  { id: '11', threadId: 'THR-011', userId: '1', userName: 'David Smith', mode: 'Chat', startedAt: '2026-04-16T11:00:00Z', duration: 150, messageCount: 5, status: 'Active', messages: [
    { id: 'm1', type: 'bot', content: 'Hi David! How can I help you today?', timestamp: '2026-04-16T11:00:00Z' },
    { id: 'm2', type: 'user', content: 'Checking on my latest claim status', timestamp: '2026-04-16T11:00:15Z' },
  ] },
  { id: '12', threadId: 'THR-012', userId: '3', userName: 'Mike Brown', mode: 'Voice', startedAt: '2026-04-16T12:00:00Z', duration: 45, messageCount: 2, status: 'Abandoned', messages: [
    { id: 'm1', type: 'bot', content: 'Hello! Welcome to ClaimAI voice support.', timestamp: '2026-04-16T12:00:00Z' },
  ] },
  { id: '13', threadId: 'THR-013', userId: '5', userName: 'James Wilson', mode: 'Chat', startedAt: '2026-04-14T09:00:00Z', duration: 540, messageCount: 16, status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Good morning! How can I assist you?', timestamp: '2026-04-14T09:00:00Z' },
    { id: 'm2', type: 'user', content: 'I need to update my claim details', timestamp: '2026-04-14T09:00:15Z' },
  ] },
  { id: '14', threadId: 'THR-014', userId: '8', userName: 'Sophia Anderson', mode: 'Chat', startedAt: '2026-04-13T14:00:00Z', duration: 300, messageCount: 8, status: 'Completed', messages: [
    { id: 'm1', type: 'bot', content: 'Hi! What brings you here today?', timestamp: '2026-04-13T14:00:00Z' },
    { id: 'm2', type: 'user', content: 'Want to know about my hailstorm damage claim', timestamp: '2026-04-13T14:00:20Z' },
  ] },
  { id: '15', threadId: 'THR-015', userId: '2', userName: 'Sarah Johnson', mode: 'Voice', startedAt: '2026-04-16T14:00:00Z', duration: 180, messageCount: 6, status: 'Active', messages: [
    { id: 'm1', type: 'bot', content: 'Welcome back, Sarah! How can I help?', timestamp: '2026-04-16T14:00:00Z' },
    { id: 'm2', type: 'user', content: 'I want to add more photos to my pending claim', timestamp: '2026-04-16T14:00:15Z' },
  ] },
];

export const mockClaimsTrend: ClaimsTrendData[] = Array.from({ length: 30 }, (_, i) => {
  const date = new Date(2026, 2, 18 + i);
  return {
    date: date.toISOString().split('T')[0],
    submitted: Math.floor(Math.random() * 15) + 5,
    approved: Math.floor(Math.random() * 10) + 2,
    rejected: Math.floor(Math.random() * 5) + 1,
  };
});

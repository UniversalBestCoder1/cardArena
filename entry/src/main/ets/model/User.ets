export interface RefereeProfile {
  specializedGame: string[]; // e.g. ['YGO', 'MTG']
  specializedFormats: string[]; // e.g. ['Standard', 'Commander']
  bio: string;
  yearsOfExperience: number;
}

export interface User {
  id: string;
  username: string;
  role: 'MANAGER' | 'STAFF' | 'PLAYER' | 'REFEREE' | 'ADMIN';
  wallet_balance?: number;
  refereeProfile?: RefereeProfile;
  // [New] Social Status
  lfgStatus?: 'IDLE' | 'LFG_YGO' | 'LFG_MTG' | 'LFG_EDH';
  lfgMessage?: string;
}
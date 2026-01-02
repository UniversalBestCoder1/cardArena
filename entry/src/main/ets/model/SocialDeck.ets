import { Deck } from './PlayerDeck';

export interface DeckPost {
  id: string;
  userId: string;
  username?: string; // For display
  deck: Deck;
  title: string;
  description: string;
  likes: number;
  createdAt: number;
  isLikedByMe?: boolean;
}

export interface DeckComment {
  id: number;
  postId: string;
  userId: string;
  username?: string;
  content: string;
  createdAt: number;
}

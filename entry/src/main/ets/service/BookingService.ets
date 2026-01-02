import { MockService } from '../mock/MockService';
import { Seat } from '../model/Seat';
import { User } from '../model/User';

export class BookingService {
  
  static async getSeats(): Promise<Seat[]> {
    return MockService.getSeats();
  }

  static async bookSeat(seatId: string): Promise<boolean> {
    return MockService.bookSeat(seatId);
  }

  static async getAvailableReferees(): Promise<User[]> {
    return MockService.getAvailableReferees();
  }
}
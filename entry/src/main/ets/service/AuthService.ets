import { MockService } from '../mock/MockService';
import { User } from '../model/User';

export class AuthService {
  
  static async login(username: string, password: string): Promise<User | null> {
    return MockService.login(username, password);
  }

  static async register(username: string, password: string, role: string): Promise<boolean> {
    return MockService.register(username, password, role);
  }

  static logout(): void {
    MockService.logout();
  }

  static getCurrentUser(): User | null {
    return MockService.getCurrentUser();
  }

  static async getUserBalance(): Promise<number> {
    return MockService.getUserBalance();
  }

  static async rechargeWallet(amount: number): Promise<boolean> {
    return MockService.rechargeWallet(amount);
  }
}
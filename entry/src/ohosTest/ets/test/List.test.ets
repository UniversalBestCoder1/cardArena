import abilityTest from './Ability.test';
import deckIntegrationTest from './DeckIntegration.test';

export default function testsuite() {
  abilityTest();
  deckIntegrationTest();
}
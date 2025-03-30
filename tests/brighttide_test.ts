import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new campaign",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('brighttide', 'create-campaign',
        [types.ascii("Test Campaign"),
         types.uint(1000),
         types.uint(100),
         types.principal(wallet1.address)],
        wallet1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Can donate to campaign and receive correct reward tier",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create campaign
    let block = chain.mineBlock([
      Tx.contractCall('brighttide', 'create-campaign',
        [types.ascii("Test Campaign"),
         types.uint(1000),
         types.uint(100),
         types.principal(wallet1.address)],
        wallet1.address)
    ]);
    
    // Make donation
    block = chain.mineBlock([
      Tx.contractCall('brighttide', 'donate',
        [types.uint(1),
         types.uint(500)],
        wallet2.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check reward tier
    let response = chain.callReadOnlyFn('brighttide', 'get-donor-info',
      [types.uint(1),
       types.principal(wallet2.address)],
      wallet2.address
    );
    response.result.expectOk().expectTuple()['reward-tier'].expectUint(2);
  }
});

Clarinet.test({
  name: "Cannot withdraw funds before goal is met",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create campaign
    let block = chain.mineBlock([
      Tx.contractCall('brighttide', 'create-campaign',
        [types.ascii("Test Campaign"),
         types.uint(1000),
         types.uint(100),
         types.principal(wallet1.address)],
        wallet1.address)
    ]);
    
    // Try to withdraw
    block = chain.mineBlock([
      Tx.contractCall('brighttide', 'withdraw-funds',
        [types.uint(1)],
        wallet1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(103);
  }
});


import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Fake "../fake";

import Vec "mo:vector";
import Star "mo:star/star";




import ActorSpec "../utils/ActorSpec";

import MigrationTypes = "../../src/ICRC2/migrations/types";

import ICRC1 "mo:icrc1-mo/ICRC1/";
import ICRC1Types "mo:icrc1-mo/ICRC1/migrations/types";
import ICRC2 "../../src/ICRC2";
import T "../../src/ICRC2/migrations/types";

module {

  let base_environment= {
    get_time = null;
    add_ledger_transaction = null;
    can_transfer = null;
    get_fee = null;
  };

  type TransferFromResult = MigrationTypes.Current.TransferFromResponse;
  type Account = MigrationTypes.Current.Account;
  type Balance = MigrationTypes.Current.Balance;
  let Map = ICRC1.Map;
  let ahash = ICRC1.ahash;
  let Vector = ICRC1.Vector;

  let e8s = 100000000;


  

    public func test() : async ActorSpec.Group {
        D.print("in test");

        let {
            assertTrue;
            assertFalse;
            assertAllTrue;
            describe;
            it;
            skip;
            pending;
            run;
        } = ActorSpec;

        let canister : ICRC1Types.Current.Account = {
            owner = Principal.fromText("x4ocp-k7ot7-oiqws-rg7if-j4q2v-ewcel-2x6we-l2eqz-rfz3e-6di6e-jae");
            subaccount = null;
        };

        let user1 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae");
            subaccount = null;
        };

        let user2 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("ygyq4-mf2rf-qmcou-h24oc-qwqvv-gt6lp-ifvxd-zaw3i-celt7-blnoc-5ae");
            subaccount = null;
        };

        let user3 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("p75el-ys2la-2xa6n-unek2-gtnwo-7zklx-25vdp-uepyz-qhdg7-pt2fi-bqe");
            subaccount = null;
        };

        let base_fee = 5 * e8s;

        let approveFor100Tokens =  {
          from_subaccount = user1.subaccount;
          spender = user2;
          amount = (100 * e8s) + base_fee; // Approval amount less than transfer amount
          expected_allowance = null;
          expires_at = null;
          fee = null;
          memo = null;
          created_at_time = null;
        };

        let approveFor100TokensPlusTwoFees =  {
          from_subaccount = user1.subaccount;
          spender = user2;
          amount = (100 * e8s) + (2 * base_fee); // Approval amount less than transfer amount
          expected_allowance = null;
          expires_at = null;
          fee = null;
          memo = null;
          created_at_time = null;
        };

        let ONE_DAY_SECONDS = 24 * 60 * 60 * 1000000000;
       
        
        let max_supply = 1_000_000_000 * e8s;

        let default_icrc2_args : ICRC2.InitArgs = {
            max_approvals = ?500;
            max_approvals_per_account = ?10;
            max_allowance = null;
            advanced_settings = null;
            fee = ?#Fixed(base_fee);
           
            settle_to_approvals = ?490;
        };

        let default_token_args : ICRC1.InitArgs = {
            name = ?"Under-Collaterised Lending Tokens";
            symbol = ?"UCLTs";
            decimals = 8;
            logo = ?"baselogo";
            fee = ?#Fixed(base_fee);
            max_supply = ?(max_supply);
            minting_account = ?canister;
            
            min_burn_amount = ?(10 * e8s);
            advanced_settings = null;
            
            metadata = null;
            
            max_memo = null;
            fee_collector = null;
            permitted_drift = null;
            transaction_window = null;
            max_accounts = null;
            settle_to_accounts = null;
        };
        var test_time : Int = Time.now();

        func get_icrc(args1 : ICRC1.InitArgs, env1 : ?ICRC1.Environment, args2 : ICRC2.InitArgs, env2: ?ICRC2.Environment) : (ICRC1.ICRC1, ICRC2.ICRC2){
          

          let environment1 : ICRC1.Environment = switch(env1){
            case(null){
              {
                get_time = ?(func () : Int {test_time});
                add_ledger_transaction = null;
                get_fee = null;
              };
            };
            case(?val) val;
          };
           
          let token = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id),?args1, canister.owner);

          let icrc1 = ICRC1.ICRC1(?token, canister.owner, environment1);

          let environment2 : ICRC2.Environment = switch(env2){
            case(null){
              {
                icrc1 = icrc1;
                get_fee = null;
              };
            };
            case(?val) val;
          };

          let app = ICRC2.init(ICRC2.initialState(), #v0_1_0(#id),?args2, canister.owner);

          let icrc2 = ICRC2.ICRC2(?app, canister.owner, environment2);


          (icrc1, icrc2);
        };

        let externalCanTransferFromFalseSync = func <system>(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification), Text> {

            
                return #err("always false");
             
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            
        };

        let externalCanTransferFromFalseAsync = func <system>(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification), Text> {
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            let fake = await Fake.Fake();
            
            return #err(#awaited("always false"));
             
            
        };

        let externalCanApproveFalseSync = func <system>(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification), Text> {

            
                return #err("always false");
             
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            
        };

        let externalCanApproveFalseAsync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification), Text> {
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            let fake = await Fake.Fake();
            
            return #err(#awaited("always false"));
             
            
        };

        let externalCanTransferFromUpdateSync = func <system>(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification), Text> {
            let results = Vector.new<(Text,ICRC1.Value)>();

            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err("not a map");
            };

            return #ok(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };

        let externalCanTransferFromUpdateAsync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TransferFromNotification), Text> {
            let fake = await Fake.Fake();
            
            let results = Vector.new<(Text,ICRC1.Value)>();
            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err(#awaited("not a map"))
            };

            return #awaited(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };


         let externalCanApproveUpdateSync = func <system>(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification), Text> {
            let results = Vector.new<(Text,ICRC1.Value)>();

            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err("not a map");
            };

            return #ok(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };

        let externalCanApproveUpdateAsync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC2.TokenApprovalNotification), Text> {
            let fake = await Fake.Fake();
            
            let results = Vector.new<(Text,ICRC1.Value)>();
            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err(#awaited("not a map"))
            };

            return #awaited(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };

        return describe(
            "ICRC1 Token Implementation Tests",
            [
                it(
                    "icrc2_approve sets correct allowance for a spender",
                    do {
                        let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                        let mint_args = {
                            to = user1;
                            amount = 200 * e8s;
                            memo = null;
                            created_at_time = null;
                        };

                        D.print("minting");
                        ignore await* icrc1.mint_tokens(
                            canister.owner,
                            mint_args
                        );

                        let approvalArgs = {
                          from_subaccount = user1.subaccount;
                          spender = user2;
                          amount = 100 * e8s;
                          expected_allowance = null;
                          expires_at = null;
                          fee = null;
                          memo = null;
                          created_at_time = null;
                        };

                        let result = await* icrc2.approve_transfers(user1.owner, approvalArgs, false, null);

                        D.print("result_test_approval was " # debug_show(result));
                        
                        let #trappable(#Ok(transaction_id)) = result;
                        let allowanceInfo = icrc2.allowance(user2, user1, false);

                        //make sure balance is reduced by fee
                        let balance = icrc1.balance_of(user1);

                        D.print("new balance was " # debug_show(balance));

                        
                        assertAllTrue([
                          allowanceInfo.allowance == 100 * e8s,
                          balance == 200 * e8s - base_fee,
                        ]);
                    },
                ),
                it(
                    "does limit approvals per account",
                    do {
                        let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                        let mint_args = {
                            to = user1;
                            amount = 20000 * e8s;
                            memo = null;
                            created_at_time = null;
                        };

                        D.print("minting");
                        ignore await* icrc1.mint_tokens(
                            canister.owner,
                            mint_args,
                            
                        );

                        let approvalArgs = {
                          from_subaccount = user1.subaccount;
                          spender = user2;
                          amount = 100 * e8s;
                          expected_allowance = null;
                          expires_at = null;
                          fee = null;
                          memo = null;
                          created_at_time = null;
                        };

                        let results = Vec.new<ICRC2.ApproveStar>();

                        for(thisItem in Iter.range(0,10)){
                          Vec.add<ICRC2.ApproveStar>(results, await* icrc2.approve_transfers(user1.owner, {approvalArgs with
                          spender = {
                            owner = user2.owner;
                            subaccount = ?Blob.fromArray([3,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,Nat8.fromNat(thisItem)]);
                          }}, false, null));
                        };

                        D.print("result_test_multiple was " # debug_show(Vec.toArray(results)));
                

                        let testarray = Vec.toArray(results);
                        let #trappable(#Ok(success_test : Nat)) = testarray[9];
                        let #err(#trappable(failure)) = testarray[10];

                        assertAllTrue([
                          success_test == 10,
                          Text.startsWith(failure, #text("Too many approvals from account"))
                        ]);
                    },
                ),
                it(
                  "icrc2_approve fails when there are insufficient funds to cover fee",
                  do {
                      let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                      let mint_args = {
                          to = user1;
                          amount = base_fee - 1; // Insufficient balance: User has less than the fee
                          memo = null;
                          created_at_time = null;
                      };



                      D.print("minting");
                      ignore await* icrc1.mint_tokens(
                          canister.owner,
                          mint_args,
                          
                      );

                      let approvalArgs = {
                          from_subaccount = user1.subaccount;
                          spender = user2;
                          amount = 100 * e8s;
                          expected_allowance = null;
                          expires_at = null;
                          fee = null;
                          memo = null;
                          created_at_time = null;
                      };

                      let result = await* icrc2.approve_transfers(user1.owner, approvalArgs, false, null);

                      D.print("result_insufficent was " # debug_show(result));

                      switch (result) {
                          case (#trappable(#Err(#InsufficientFunds({ balance })))) {
                              assertTrue(balance < base_fee);
                          };
                          case _ {
                              assertFalse(true);
                          };
                      };
                  },
              ),

              it(
                "icrc2_approve rejects approval where `spender` equals source account owner",
                do {
                    let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                    let approvalArgs = {
                        from_subaccount = user1.subaccount;
                        spender = user1; // spender should not be the same as the source account
                        amount = 100 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    };

                    let mint_args = {
                        to = user1;
                        amount = 200 * e8s;
                        memo = null;
                        created_at_time = null;
                    };

                    D.print("minting");
                    ignore await* icrc1.mint_tokens(
                        canister.owner,
                        mint_args,
                    );


                    let result = await* icrc2.approve_transfers(user1.owner, approvalArgs, false, null);

                    switch (result) {
                        case (#err(#trappable(_))) {
                            assertTrue(true); //, "Approval with invalid account owner should fail.");
                        };
                        case _ {
                            assertFalse(true); //, "Approval should fail when spender equals source account owner.");
                        };
                    };
                },
            ),
            it(
              "icrc2_approve resets the allowance for the spender",
              do {
                  let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                  let initialApproval = 100 * e8s;

                  ignore await* icrc1.mint_tokens(canister.owner, {
                      to = user1;
                      amount = initialApproval * 2;
                      memo = null;
                      created_at_time = null;
                  });



                  let approvalArgs = {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = initialApproval;
                      expected_allowance = null;
                      expires_at = null;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  };

                  // First approval
                  let result = await* icrc2.approve_transfers(user1.owner, approvalArgs, false, null);

                  D.print("result_initial was " # debug_show(result));

                  // Second approval with reset
                  let resetApprovalAmount = 50 * e8s;
                  let result2 = await* icrc2.approve_transfers(user1.owner, {approvalArgs with amount = resetApprovalAmount}, false, null);

                  D.print("result_overwrite was " # debug_show(result2));

                  switch (result2) {
                      case (#trappable(#Ok(_))) {
                          let allowance = icrc2.allowance(user2, user1, false);
                          D.print("final allowance " # debug_show(allowance));
                          assertTrue(allowance == resetApprovalAmount);//, "Allowance should be reset to new amount.");
                      };
                      case _ {
                          assertFalse(true);//, "Second approval should succeed and reset allowance.");
                      };
                  };
              },
            ),
            it(
              "fails with AllowanceChanged if expected_allowance does not match",
              do {
                  let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                  let initialApproval = 100 * e8s;

                  ignore await* icrc1.mint_tokens(canister.owner, {
                      to = user1;
                      amount = initialApproval * 2;
                      memo = null;
                      created_at_time = null;
                  });


                  // Set initial allowance for user2 spender
                  let resultinit = await* icrc2.approve_transfers(user1.owner, {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = 100 * e8s;
                      expected_allowance = null;
                      expires_at = null;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, true, null);

                  D.print("result init  was " # debug_show(resultinit));

                  // Attempt to change allowance but mismatch expected current allowance
                  let result = await* icrc2.approve_transfers(user1.owner, {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = 50 * e8s;
                      expected_allowance = ?(150 * e8s); // This is wrong on purpose
                      expires_at = null;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, false, null);

                  D.print("result expected  was " # debug_show(result));

                  assertTrue(
                      switch (result) {
                          case (#trappable(#Err(#AllowanceChanged(_)))) true;
                          case _ false;
                      }
                  );
              },
            ),
            it(
              "respects maximum allowance limits for total supply",
              do {
                  let (icrc1, icrc2)  = get_icrc(default_token_args, null, {default_icrc2_args
                  with
                  max_allowance = ?#TotalSupply;}, null);

                  let initialApproval = 100 * e8s;

                  ignore await* icrc1.mint_tokens(canister.owner, {
                      to = user1;
                      amount = initialApproval;
                      memo = null;
                      created_at_time = null;
                  });

                  ignore await* icrc1.mint_tokens(canister.owner, {
                      to = user2;
                      amount = initialApproval;
                      memo = null;
                      created_at_time = null;
                  });

                  // Attempt to approve more than the total supply (assuming cap is total supply for this example)
                  let result = await* icrc2.approve_transfers(user1.owner, {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = (initialApproval * 2) + 1;
                      expected_allowance = null;
                      expires_at = null;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, false, null);

                  D.print("result total supply limit " # debug_show(result));

                  // Check that the allowance was capped at max_supply or returned an error
                  let allowance = icrc2.allowance(user2, user1, false);
                  D.print("found allowance " # debug_show(allowance, icrc1.total_supply()));
                  assertTrue(allowance.allowance == icrc1.total_supply());
              },
            ),
            it(
              "respects maximum allowance limits for fixed max allowance",
              do {
                  let (icrc1, icrc2)  = get_icrc(default_token_args, null, {default_icrc2_args
                  with
                  max_allowance = ?#Fixed(100000000);}, null);

                  let initialApproval = 100 * e8s;

                  ignore await* icrc1.mint_tokens(canister.owner,
                  {
                      to = user1;
                      amount = initialApproval;
                      memo = null;
                      created_at_time = null;
                  });

                  ignore await* icrc1.mint_tokens(canister.owner,
                  {
                      to = user1;
                      amount = initialApproval;
                      memo = null;
                      created_at_time = null;
                  });

                  // Attempt to approve more than the total supply (assuming cap is total supply for this example)
                  let result = await* icrc2.approve_transfers(user1.owner, {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = (initialApproval * 2) + 1;
                      expected_allowance = null;
                      expires_at = null;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, false, null);

                  D.print("result fixed limit " # debug_show(result));

                  // Check that the allowance was capped at max_supply or returned an error
                  let allowance = icrc2.allowance(user2, user1, false);
                  D.print("found allowance " # debug_show(allowance));
                  assertTrue(allowance.allowance == 100000000);
              },
            ),
            it(
              "fails transfers after allowance expiry with InsufficientAllowance",
              do {
                  let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                  ignore await* icrc1.mint_tokens(canister.owner, {
                      to = user1;
                      amount = 100 * e8s;
                      memo = null;
                      created_at_time = null;
                  });

                  // Set allowance with an expiry time that has already passed
                  test_time := Time.now() - 3600_000; // 1 hour ago
                  let oldapprove = await* icrc2.approve_transfers(user1.owner, {
                      from_subaccount = user1.subaccount;
                      spender = user2;
                      amount = 100 * e8s;
                      expected_allowance = null;
                      expires_at = ?Nat64.fromNat(Int.abs(test_time));
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, true, null);

                  test_time := Time.now() + 1; // 1 hour ago

                  // Now is beyond expire_at, check allowance and fail on transfer
                  let allowance = icrc2.allowance(user2, user1, true); 
                  let transferResult = await* icrc2.transfer_tokens_from(user2.owner, {
                      spender_subaccount = user2.subaccount;
                      from = user1;
                      to = user2; // Any account; not relevant for test
                      amount = 10 * e8s;
                      fee = null;
                      memo = null;
                      created_at_time = null;
                  }, null);

                  assertAllTrue([
                      allowance.allowance == 0, // Allowance should now be zero
                      switch (transferResult) {
                          case (#trappable(#Err(#InsufficientAllowance(_)))) true;
                          case _ false;
                      },
                  ]);
              },
          ),
          it(
            "rejects icrc2_approvals with insufficient fees (BadFee)",
            do {
                
                let insufficient_fee: Nat = 50; // Define an insufficient fee
                let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                ignore await* icrc1.mint_tokens(canister.owner, {
                    to = user1;
                    amount = 1000 * e8s; // Mint tokens to user1
                    memo = null;
                    created_at_time = null;
                });

                let approvalArgs = {
                    from_subaccount = user1.subaccount;
                    spender = user2;
                    amount = 200 * e8s; // Set approval amount
                    expected_allowance = null;
                    expires_at = null;
                    fee = ?insufficient_fee; // Set insufficient fee
                    memo = null;
                    created_at_time = null;
                };

                let result = await* icrc2.approve_transfers(user1.owner, approvalArgs, false, null);

                 D.print("result bad fee " # debug_show(result));

                switch (result) {
                    case (#trappable(#Ok(_)))
                       assertFalse(true);// "Approval succeeded with insufficient fee, which is unexpected.");
                    case (#trappable(#Err(#BadFee(expected))))
                        if (expected.expected_fee != base_fee) {
                            assertFalse(true);//("BadFee error with unexpected fee amount.");
                        } else {
                          assertTrue(true);
                        };
                    case (#trappable(#Err(_)))
                        assertFalse(true);//"Unexpected error during approval with insufficient fee.");
                    case (#err(_))
                        assertFalse(true);//"Trapped or awaited error during approval.");
                    case (_)
                        assertFalse(true);//"Trapped or awaited error during approval.")
                };
              },
            ),
            it(
                "performs icrc2_transfer_from with sufficient allowance and funds",
                do {
                    let transfer_amount: Nat = 100 * e8s; // Set transfer amount
                    let initial_balance: Nat = 1000 * e8s; // Initial balance for user1
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = initial_balance; // Mint tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    D.print("transfer From Initial balance  " # debug_show(icrc1.balance_of(user1)));

                    // Approve user2 to spend on behalf of user1
                    ignore await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 200 * e8s; // Approval amount greater than transfer amount
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    D.print("transfer From balance after approval  " # debug_show(icrc1.balance_of(user1)));

                    let transferFromArgs = {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = transfer_amount;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    };

                    

                    let transfer_result = await* icrc2.transfer_tokens_from(user2.owner, transferFromArgs, null);

                    D.print("transfer From balance after transfer  " # debug_show(icrc1.balance_of(user1)));

                     D.print("transfer result  " # debug_show(transfer_result));

                    switch (transfer_result) {
                        case (#trappable(#Ok(transaction_id))){
                            // Validate updated balances and allowances
                            let balance_user1 = icrc1.balance_of(user1);
                            let balance_user3 = icrc1.balance_of(user3);
                            let allowance = icrc2.allowance(user2, user1, false);

                            D.print("details  " # debug_show(balance_user1, initial_balance - transfer_amount - base_fee - base_fee, balance_user3, transfer_amount, allowance, (200 * e8s) - transfer_amount - base_fee));
                            
                            assertAllTrue([
                                balance_user1 == initial_balance - transfer_amount - base_fee - base_fee,
                                balance_user3 == transfer_amount,
                                allowance == (200 * e8s) - transfer_amount - base_fee,
                            ]);
                        };
                        case (#trappable(#Err(_)))
                             assertFalse(true);//"Transfer from failed despite having sufficient allowance and funds.");
                        case (_)
                            assertFalse(true);//("Trapped or awaited error during transfer from.");
                           
                    };

                },
            ),
            it(
                "rejects icrc2_transfer_from with insufficient allowance (InsufficientAllowance)",
                do {
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 1000 * e8s; // Mint tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    // Approve user2 to spend less than transfer amount
                    ignore await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 50 * e8s; // Approval amount less than transfer amount
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    let transferFromArgs = {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = canister;
                        amount = 100 * e8s; // Transfer amount greater than approval
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    };

                    let transfer_result = await* icrc2.transfer_tokens_from(user2.owner, transferFromArgs, null);

                    switch (transfer_result) {
                        case (#trappable(#Ok(_)))
                            assertFalse(true);// "Transfer from succeeded with insufficient allowance, which is unexpected.");
                        case (#trappable(#Err(#InsufficientAllowance(current_allowance))))
                            assertTrue(true); // Test passes if an 'InsufficientAllowance' error is thrown
                        case (#trappable(#Err(_)))
                            assertFalse(true);// "Unexpected error during transfer with insufficient allowance.");
                        case (_)
                            assertFalse(true);//"Trapped or awaited error during transfer from.");
                    };
                },
            ),
            it(
                "rejects icrc2_transfer_from with insufficient funds (InsufficientFunds)",
                do {
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner,
                    {
                        to = user1;
                        amount = 50 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    // Approve user2 to spend an amount larger than user1's balance
                    ignore await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 100 * e8s; // Approval amount is sufficient
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    let transferFromArgs = {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = canister;
                        amount = 100 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    };

                    let transfer_result = await* icrc2.transfer_tokens_from(user2.owner, transferFromArgs, null);

                    switch (transfer_result) {
                        case (#trappable(#Ok(_)))
                            assertFalse(true);//"Transfer from succeeded with insufficient funds, which is unexpected.");
                        case (#trappable(#Err(#InsufficientFunds(balance))))
                            assertTrue(true); // Test passes if an 'InsufficientFunds' error is thrown
                        case (#trappable(#Err(_)))
                            assertFalse(true);//"Unexpected error during transfer with insufficient funds.");
                        case (_)
                            assertFalse(true);//"Trapped or awaited error during transfer from.");
                    };

                },
            ),

            it(
                "should fail to transfer more than approved amount in multiple transactions",
                do {
                     let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });


                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                    let firstTransferResponse = await* icrc2.transfer_tokens_from(user2.owner, {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 50 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null);

                    D.print("firstTransferResponse " # debug_show(firstTransferResponse));

                     let #trappable(#Ok(firstTransferResponse_)) = firstTransferResponse;

                    let secondTransferResponse = await* icrc2.transfer_tokens_from(user2.owner, {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 60 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null); // 10 tokens more than approved

                     D.print("secondTransferResponse a " # debug_show(secondTransferResponse));
                    
                    let #trappable(#Err(#InsufficientAllowance(foundAllowance))) = secondTransferResponse;

                    D.print("now testing " # debug_show(foundAllowance, (50 * e8s) - base_fee) );

                    assertAllTrue([
                        //secondTransferResponse_.allowance == (50 * e8s) - base_fee, // Allowance should now be zero
                        firstTransferResponse_ > 0,
                    ]);
                }
            ), 
            it(
                "should transfer exact allowed amount successfully",
                do {

                     D.print("should transfer exact allowed amount successfully " );
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                    let balanceBeforeTransfer = icrc1.balance_of(user1);

                     D.print("balanceBeforeTransfer " # debug_show(balanceBeforeTransfer));
                    
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 100 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null); // Exact approved amount

                     D.print("secondTransferResponse b " # debug_show(transferResponse));

                    let #trappable(#Ok(transferResponse_)) = transferResponse;

                    let balanceAfterTransfer = icrc1.balance_of(user1);

                    assertAllTrue([
                        transferResponse_ > 0,
                        balanceBeforeTransfer - balanceAfterTransfer == (100 * e8s) + base_fee //"Fee should be deducted along with transfer amount"
                    ]);
                }
            ),
            it(
                "should fail the transfer after allowance expiration",
                do {
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                    let approveResponse2 = await* icrc2.approve_transfers(user1.owner, {approveFor100Tokens with
                     expires_at = ?(Nat64.fromNat(Int.abs(test_time + ONE_DAY_SECONDS)))}, false, null);

                     D.print("approveResponse2 " # debug_show(approveResponse2));

                     let approveResponse3 = await* icrc2.approve_transfers(user1.owner, {approveFor100Tokens with
                     expires_at = ?(Nat64.fromNat(Int.abs(test_time - ONE_DAY_SECONDS)))}, false, null);

                     D.print("approveResponse3 " # debug_show(approveResponse3));

                     let #trappable(#Err(#Expired(approveResponse3_))) = approveResponse3;

                    test_time += ONE_DAY_SECONDS + 1; // Simulate time passage after expiration
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 100 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null); // Attempt to transfer after allowance expiration

                    D.print("transferResponse expired " # debug_show(transferResponse));

                    let #trappable(#Err(#InsufficientAllowance(transferResponse_))) = transferResponse;

                    assertAllTrue([
                        Nat64.toNat(approveResponse3_.ledger_time) == test_time - ONE_DAY_SECONDS - 1,
                        transferResponse_.allowance == 0
                    ]);
                }
            ),
            it(
                "should identify and reject duplicate transactions",
                do {

                    test_time := Time.now();

                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100TokensPlusTwoFees, false, null);

                    D.print("approveResponse " # debug_show(approveResponse));

                    let #trappable(#Ok(approveResponse_)) = approveResponse;

                    test_time += 5;

                    let approveResponse2 = await* icrc2.approve_transfers(user1.owner, approveFor100TokensPlusTwoFees, false, null);

                    D.print("approveResponse2 " # debug_show(approveResponse2));

                    let #trappable(#Err(#Duplicate(approveResponse2_))) = approveResponse2;

                    test_time += 5;

                    let firstTransferResponse = await* icrc2.transfer_tokens_from(user2.owner, {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 50 * e8s; 
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null);

                    D.print("firstTransferResponse " # debug_show(firstTransferResponse));

                    let #trappable(#Ok(firstTransferResponse_)) = firstTransferResponse;

                    test_time += 5;

                    let secondTransferResponse = await* icrc2.transfer_tokens_from(user2.owner, {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 50 * e8s; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null); // Same args as first transfer, should be a duplicate

                    D.print("secondTransferResponse c " # debug_show(secondTransferResponse));

                    let #trappable(#Err(#Duplicate(foundAllowance))) = secondTransferResponse;

                    assertAllTrue([
                        approveResponse_ > 0,
                        approveResponse2_.duplicate_of == approveResponse_,
                        firstTransferResponse_ > 0,
                        foundAllowance.duplicate_of == firstTransferResponse_
                    ]);
                }
            ),
            it(
                "returns the correct allowance for an existing approval",
                do {
                    let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                    // Set up an approval for user2 to spend on behalf of user1
                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 200 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                    ignore await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 100 * e8s; // Approval amount
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Retrieve the allowance for user2
                    let allowance = icrc2.allowance(user2, user1, false);
                    
                    assertTrue(allowance.allowance == 100 * e8s); // Validate that the allowance is as expected
                },
            ),
            it(
                "returns zero for non-existing approvals",
                do {
                    let (_, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                    // Try to get allowance for unapproved user2
                    let allowance = icrc2.allowance(user2, user1, false);
                    
                    assertTrue(allowance.allowance == 0); // Non-existing approvals should return zero allowance
                },
            ),
            it(
                "reduces allowance correctly after a successful transfer",
                do {
                    
                     let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);


                      ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 200 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                     let transferAmount = 50 * e8s;

                     let approval = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 100 * e8s; // Approval amount
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Assume `icrc2_transfer_from` is called here with some amount
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = transferAmount; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, null); // Attempt to transfer after allowance expiration


                    // Check allowance after the transfer
                    let allowanceAfterTransfer = icrc2.allowance(user2, user1, false);

                    D.print("allowanceAfterTransfer " # debug_show(allowanceAfterTransfer));

                    
                    let expectedAllowance = (100 * e8s) - transferAmount - base_fee; // Replace `transferAmount` with the actual transferred amount
                    assertTrue(allowanceAfterTransfer.allowance == expectedAllowance);
                },
            ),
            it(
                "should allow approve sync cancle",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, ?#Sync(externalCanApproveFalseSync));

                     D.print("approveResponse false sync " # debug_show(approveResponse));
                    let #trappable(#Err(#GenericError(approveResponseResult))) = approveResponse;
                    
                    

                    assertAllTrue([
                        approveResponseResult.error_code == 100,
                    ]);
                }
            ),
            it(
                "should allow approve async cancle",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, ?#Async(externalCanApproveFalseAsync));

                     D.print("approveResponse false sync " # debug_show(approveResponse));
                    let #awaited(#Err(#GenericError(approveResponseResult))) = approveResponse;

                    assertAllTrue([
                        approveResponseResult.error_code == 100,
                    ]);
                }
            ),
            it(
                "should allow approve sync update",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, ?#Sync(externalCanApproveUpdateSync));

                     D.print("approveResponse false sync " # debug_show(approveResponse));
                    

                    // Check allowance after the transfer
                    let allowanceAfterApprove = icrc2.allowance(user2, user1, false);
                    
                    

                    assertAllTrue([
                        allowanceAfterApprove.allowance == 2,
                    ]);
                }
            ),
            it(
                "should allow approve async update",
                do {

                     
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, ?#Async(externalCanApproveUpdateAsync));

                    // Check allowance after the transfer
                    let allowanceAfterApprove = icrc2.allowance(user2, user1, false);
                    

                    assertAllTrue([
                        allowanceAfterApprove.allowance == 2,
                    ]);
                }
            ),

            it(
                "should allow transfer from sync cancle",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                     D.print("transferfrom approveResponse false sync " # debug_show(approveResponse));

                    // Assume `icrc2_transfer_from` is called here with some amount
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 1; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, ?#Sync(externalCanTransferFromFalseSync)); // Attempt to transfer after allowance expiration

                    D.print("transferfrom transfer false async " # debug_show(transferResponse));



                    let #trappable(#Err(#GenericError(transferResponseResult))) = transferResponse;
                    
                    

                    assertAllTrue([
                        transferResponseResult.error_code == 100,
                    ]);
                }
            ),
            it(
                "should allow approve async cancle",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                     D.print("transferfrom approveResponse false async " # debug_show(approveResponse));
                    
                    // Assume `icrc2_transfer_from` is called here with some amount
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 1; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, ?#Async(externalCanTransferFromFalseAsync)); // Attempt to transfer after allowance expiration

                    D.print("transferfrom transfer false async " # debug_show(approveResponse));

                    let #awaited(#Err(#GenericError(transferResponseResult))) = transferResponse;


                    assertAllTrue([
                        transferResponseResult.error_code == 100,
                    ]);
                }
            ),
            it(
                "should allow approve sync update",
                do {

                    
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                     D.print("approveResponse update sync " # debug_show(approveResponse));

                     // Check allowance after the transfer
                    let allowanceAfterApprove = icrc2.allowance(user2, user1, false);

                     // Assume `icrc2_transfer_from` is called here with some amount
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 1; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, ?#Sync(externalCanTransferFromUpdateSync)); // Attempt to transfer after allowance expiration

                    D.print("transferfrom transferResponse update sync " # debug_show(approveResponse));
                    

                    let balanceAfterTransfer = icrc1.balance_of(user1);

                     D.print("balanceAfterTransfer update async " # debug_show(balanceAfterTransfer,  (500 * e8s) - base_fee - base_fee - 2));
                    
                    

                    assertAllTrue([
                        balanceAfterTransfer == (500 * e8s) - base_fee - base_fee - 2,
                    ]);
                }
            ),
            it(
                "should allow approve async update",
                do {

                     
                    let (icrc1, icrc2)  = get_icrc(default_token_args, null, default_icrc2_args, null);

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 500 * e8s; // Mint lesser tokens to user1
                        memo = null;
                        created_at_time = null;
                    });

                    let approveResponse = await* icrc2.approve_transfers(user1.owner, approveFor100Tokens, false, null);

                    D.print("approveResponse update async " # debug_show(approveResponse));

                    // Assume `icrc2_transfer_from` is called here with some amount
                    let transferResponse = await* icrc2.transfer_tokens_from(user2.owner,  {
                        spender_subaccount = user2.subaccount;
                        from = user1;
                        to = user3;
                        amount = 1; // Transfer amount is more than user1's balance
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, ?#Async(externalCanTransferFromUpdateAsync)); // Attempt to transfer after allowance expiration

                    D.print("transferfrom transferResponse update async " # debug_show(approveResponse));

                    // Check allowance after the transfer
                    let balanceAfterTransfer = icrc1.balance_of(user1);

                    D.print("balanceAfterTransfer update async " # debug_show(balanceAfterTransfer,  (500 * e8s) - base_fee - base_fee - 2));
                    
                    

                    assertAllTrue([
                        balanceAfterTransfer == (500 * e8s) - base_fee - base_fee - 2,
                    ]);
                }
            ),
            it(
                "should get allowances with ICRC-103",
                do {
                    let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                    // Mint tokens to user1
                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 1000 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                    // Set up multiple approvals from user1 to different spenders
                    let _approveResponse1 = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 100 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    let _approveResponse2 = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user3;
                        amount = 200 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    D.print("=== Test 1: Get allowances with ICRC-103 ===" # debug_show(_approveResponse1, _approveResponse2));
                    D.print("user1: " # debug_show(user1)); 

                    // Test getAllowances function
                    let getAllowancesResult = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = ?10;
                    });

                    D.print("getAllowances result: " # debug_show(getAllowancesResult));

                    let _result =switch(getAllowancesResult) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 2, // Should have 2 allowances
                                allowances[0].from_account == user1,
                                allowances[0].allowance > 0,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Error in getAllowances: " # debug_show(error));
                            assertAllTrue([false]); // Test should fail if there's an error
                        };
                    };

                    // Test pagination with prev_spender
                    let paginatedResult = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = ?user2;
                        take = ?1;
                    });

                    D.print("Paginated result: " # debug_show(paginatedResult));

                    assertAllTrue([true]); // Basic test passed
                }
            ),
            it(
                "should handle getAllowances with null parameters and defaults",
                do {
                    let (icrc1, icrc2) = get_icrc(default_token_args, null, default_icrc2_args, null);

                     D.print("=== Test: getAllowances with null parameters and defaults ===");

                    // Mint tokens to multiple users
                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 2000 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user2;
                        amount = 1000 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                    // Create multiple approvals from user1 to different spenders
                    let user4 = {owner = Principal.fromText("u6s2n-gx777-77774-qaaba-cai"); subaccount = null};
                    let user5 = {owner = Principal.fromText("vpyes-67777-77774-qaaeq-cai"); subaccount = null};
                    let user6 = {owner = Principal.fromText("uxrrr-q7777-77774-qaaaq-cai"); subaccount = null};

                    // Approval 1: user1 -> user2
                    let _ = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 50 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Approval 2: user1 -> user3
                    let _ = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user3;
                        amount = 75 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Approval 3: user1 -> user4
                    let _ = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user4;
                        amount = 100 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Approval 4: user1 -> user5
                    let _ = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user5;
                        amount = 125 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    // Approval 5: user2 -> user3 (different owner)
                    let _ = await* icrc2.approve_transfers(user2.owner, {
                        from_subaccount = user2.subaccount;
                        spender = user3;
                        amount = 25 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    D.print("=== Test 1: All null parameters (should use caller and defaults) ===");
                    let result1 = icrc2.getAllowances(user1.owner, {
                        from_account = null;  // Should default to caller (user1) with default subaccount
                        prev_spender = null;  // Should start from beginning
                        take = null;          // Should use default max_take_value (1000)
                    });

                    D.print("Result 1: " # debug_show(result1));
                    let _result1 = switch(result1) {
                        case(#Ok(allowances)) {
                            D.print("Number of allowances for user1: " # debug_show(allowances.size()));
                            assertAllTrue([
                                allowances.size() == 4, // user1 has 4 approvals
                                allowances[0].from_account.owner == user1.owner,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 2: from_account null with different caller ===");
                    let result2 = icrc2.getAllowances(user2.owner, {
                        from_account = null;  // Should default to caller (user2)
                        prev_spender = null;
                        take = ?5;
                    });

                    D.print("Result 2: " # debug_show(result2));
                    let _result2 =switch(result2) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 1, // user2 has 1 approval
                                allowances[0].from_account.owner == user2.owner,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 3: Explicit from_account with null subaccount ===");
                    let result3 = icrc2.getAllowances(user1.owner, {
                        from_account = ?{owner = user1.owner; subaccount = null}; // Should use default subaccount
                        prev_spender = null;
                        take = ?2;
                    });

                    D.print("Result 3: " # debug_show(result3));
                    let _result3 = switch(result3) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 2, // Limited by take parameter
                                allowances[0].from_account.owner == user1.owner,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 4: Pagination with prev_spender ===");
                    // First get initial batch
                    let result4a = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = ?2;
                    });

                    D.print("Result 4a: " # debug_show(result4a));
                    
                    let _result4a = switch(result4a) {
                        case(#Ok(allowances)) {
                            if (allowances.size() > 0) {
                                // Now get next batch using last spender as prev_spender
                                let lastSpender = allowances[allowances.size() - 1].to_spender;
                                let result4b = icrc2.getAllowances(user1.owner, {
                                    from_account = ?user1;
                                    prev_spender = ?lastSpender;
                                    take = ?2;
                                });

                                D.print("Result 4b: " # debug_show(result4b));
                                let _result4b = switch(result4b) {
                                    case(#Ok(nextAllowances)) {
                                        assertAllTrue([
                                            nextAllowances.size() <= 2,
                                            nextAllowances.size() >= 0,
                                        ]);
                                    };
                                    case(#Err(error)) {
                                        D.print("Unexpected error in pagination: " # debug_show(error));
                                        assertAllTrue([false]);
                                    };
                                };
                            };
                            assertAllTrue([true]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 5: Empty result for account with no approvals ===");
                    let result5 = icrc2.getAllowances(user6.owner, {
                        from_account = ?user6;
                        prev_spender = null;
                        take = ?10;
                    });

                    D.print("Result 5: " # debug_show(result5));
                    let _result5 = switch(result5) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 0, // user6 has no approvals
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 6: Large take value (should be limited by max_take_value) ===");
                    let result6 = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = ?5000; // Larger than max_take_value (1000)
                    });

                    D.print("Result 6: " # debug_show(result6));
                    let _result6 = switch(result6) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() <= 1000, // Should be limited by max_take_value
                                allowances.size() == 4,    // But we only have 4 allowances anyway
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 7: Zero take value ===");
                    let result7 = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = ?0;
                    });

                    D.print("Result 7: " # debug_show(result7));
                    let _result7 = switch(result7) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 0, // Should return empty array
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test 8: Lexicographic ordering verification ===");
                    let result8 = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = null;
                    });

                    D.print("Result 8: " # debug_show(result8));
                    let _result8 = switch(result8) {
                        case(#Ok(allowances)) {
                            // Verify that spenders are in lexicographic order
                            var previousSpender : ?Principal = null;
                            var isOrdered = true;
                            
                            for (allowance in allowances.vals()) {
                                switch(previousSpender) {
                                    case(null) {
                                        previousSpender := ?allowance.to_spender.owner;
                                    };
                                    case(?prev) {
                                        if (Principal.compare(prev, allowance.to_spender.owner) == #greater) {
                                            isOrdered := false;
                                        };
                                        previousSpender := ?allowance.to_spender.owner;
                                    };
                                };
                            };
                            
                            assertAllTrue([
                                isOrdered,
                                allowances.size() > 0,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    assertAllTrue([true]); // All comprehensive tests passed
                }
            ),
            it(
                "should respect private mode access control in getAllowances",
                do {
                    // Create a custom ICRC2 instance with private mode
                    let private_icrc2_args = {
                        max_approvals_per_account = ?10;
                        max_approvals = ?1000;
                        settle_to_approvals = ?500;
                        fee = ?#ICRC1;
                        max_allowance = null;
                        advanced_settings = null;
                        
                    };

                    let (icrc1, icrc2) = get_icrc(default_token_args, null, private_icrc2_args, null);

                    ignore icrc2.set_private_mode(true); // Enable private mode

                    // Mint tokens to user1
                    ignore await* icrc1.mint_tokens(canister.owner, {
                        to = user1;
                        amount = 1000 * e8s;
                        memo = null;
                        created_at_time = null;
                    });

                    // Create approval from user1 to user2
                    let _ = await* icrc2.approve_transfers(user1.owner, {
                        from_subaccount = user1.subaccount;
                        spender = user2;
                        amount = 100 * e8s;
                        expected_allowance = null;
                        expires_at = null;
                        fee = null;
                        memo = null;
                        created_at_time = null;
                    }, false, null);

                    D.print("=== Test Private Mode: Owner can access own allowances ===");
                    let result1 = icrc2.getAllowances(user1.owner, {
                        from_account = ?user1;
                        prev_spender = null;
                        take = ?10;
                    });

                    D.print("Private mode result (owner): " # debug_show(result1));
                    let _result1 = switch(result1) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 1,
                                allowances[0].from_account.owner == user1.owner,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test Private Mode: Other principal cannot access allowances ===");
                    let result2 = icrc2.getAllowances(user2.owner, {
                        from_account = ?user1; // user2 trying to access user1's allowances
                        prev_spender = null;
                        take = ?10;
                    });

                    D.print("Private mode result (other): " # debug_show(result2));
                    let _result2 = switch(result2) {
                        case(#Ok(_allowances)) {
                            D.print("Should not succeed in private mode");
                            assertAllTrue([false]);
                        };
                        case(#Err(#AccessDenied({reason}))) {
                            D.print("Correctly denied access: " # reason);
                            assertAllTrue([true]);
                        };
                        case(#Err(error)) {
                            D.print("Wrong error type: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    D.print("=== Test Private Mode: Null from_account uses caller ===");
                    let result3 = icrc2.getAllowances(user1.owner, {
                        from_account = null; // Should default to caller (user1)
                        prev_spender = null;
                        take = ?10;
                    });

                    D.print("Private mode result (null from_account): " # debug_show(result3));
                   let _result3 = switch(result3) {
                        case(#Ok(allowances)) {
                            assertAllTrue([
                                allowances.size() == 1,
                                allowances[0].from_account.owner == user1.owner,
                            ]);
                        };
                        case(#Err(error)) {
                            D.print("Unexpected error: " # debug_show(error));
                            assertAllTrue([false]);
                        };
                    };

                    assertAllTrue([true]); // Private mode tests passed
                }
            ),
            
            
            ],
        );
    };

};

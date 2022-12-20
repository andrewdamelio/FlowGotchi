import path from 'path';
import {
  emulator,
  init,
  shallPass,
  getAccountAddress,
  sendTransaction,
  mintFlow,
  deployContractByName,
  executeScript,
  shallRevert,
} from 'flow-js-testing';

// Increase timeout if your tests failing due to timeout
jest.setTimeout(10000);

describe('FlowGotchi', () => {

  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    // You can specify different port to parallelize execution of describe blocks
    const port = 8080;
    // Setting logging flag to true will pipe emulator output to console
    const logging = true;

    await init(basePath, {
      port
    });
    return emulator.start(port, logging);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  test('Should be able to mint a FlowGotchi', async () => {
    await deploy();

    // Setup Alice
    const Alice = await getAccountAddress('Alice');
    await mintFlow(Alice, '0.001');

    // Setup FlowGotchi collection
    await shallPass(
      sendTransaction('setup_FlowGotchi', [Alice], [])
    );

    // Mint FlowGotchi NFT
    await shallPass(
      sendTransaction('mint_FlowGotchi', [Alice], [])
    );

    // Get FlowGotchi Metadata
    let flowGotchi = await executeScript('getMetadata_FlowGotchi', [Alice])
    expect(flowGotchi[0].traits).toEqual({ health: 100, friendship: 0, mood: 0, age: 11, hunger: 0 });
  });

  test('Should ONLY be able to mint a single FlowGotchi per USER', async () => {
    await deploy();

    // Setup Alice
    const Alice = await getAccountAddress('Alice');
    await mintFlow(Alice, '0.001');

    // Setup FlowGotchi collection
    await shallPass(
      sendTransaction('setup_FlowGotchi', [Alice], [])
    );

    // Mint FlowGotchi NFT
    await shallPass(
      sendTransaction('mint_FlowGotchi', [Alice], [])
    );

    // Try and mint another, will fail since a FlowGotchi already exists for this USER
    await shallRevert(
      sendTransaction('mint_FlowGotchi', [Alice], [])
    );
  });
});

const deploy = async (initalFlow = 100.0) => {
  try {
    const Admin = await getAccountAddress('Admin');
    await mintFlow(Admin, initalFlow);

    await shallPass(
      deployContractByName({
        to: Admin,
        name: 'shared/NonFungibleToken',
      }),
    );

    await shallPass(
      deployContractByName({
        to: Admin,
        name: 'shared/FungibleToken',
      }),
    );

    await shallPass(
      deployContractByName({
        to: Admin,
        name: 'shared/MetadataViews'
      }),
    );

    await shallPass(
      deployContractByName({
        to: Admin,
        name: 'FlowGotchi'
      }),
    );
  } catch (error) {
    throw error;
  }
};
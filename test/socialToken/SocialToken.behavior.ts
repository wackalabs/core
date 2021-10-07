import { expect } from "chai";

export function shouldBehaveLikeSocialToken(): void {
  it("should return the creator address once it's minted", async function () {
    expect(await this.socialToken.connect(this.signers.admin).creator()).to.equal(
      await this.signers.admin.getAddress(),
    );
  });
}

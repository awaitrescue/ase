package ase.chunks;

import ase.Palette.PaletteEntry;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

using Lambda;

typedef Packet = {
  skipEntries:Int,
  numColors:Int,
  colors:Array<{red:Int, green:Int, blue:Int}>
}

class OldPaleteChunk extends Chunk {
  public var numPackets:Int;
  public var packets:Array<Packet> = [];

  override function getSizeWithoutHeader():Int {
    return 2 // numPackets
      + packets.map(packet -> 1 // skipEntries
        + 1 // numColors
        + (packet.colors.length * 3)).fold((packetSize:Int,
          result:Int) -> packetSize
          + result, 0);
  }

  public static function fromBytes(bytes:Bytes):OldPaleteChunk {
    var chunk = new OldPaleteChunk();
    var bi = new BytesInput(bytes);

    chunk.numPackets = bi.readUInt16();

    for (_ in 0...chunk.numPackets) {
      var newPacket:Packet = {
        skipEntries: bi.readByte(),
        numColors: bi.readByte(),
        colors: []
      };

      for (_ in 0...newPacket.numColors) {
        newPacket.colors.push({
          red: bi.readByte(),
          green: bi.readByte(),
          blue: bi.readByte()
        });
      }

      chunk.packets.push(newPacket);
    }

    return chunk;
  }

  override function toBytes(?out:BytesOutput):Bytes {
    var bo = out != null ? out : new BytesOutput();

    writeHeaderBytes(bo);

    bo.writeUInt16(numPackets);

    for (packet in packets) {
      bo.writeByte(packet.skipEntries);
      bo.writeByte(packet.numColors);

      for (c in packet.colors) {
        bo.writeByte(c.red);
        bo.writeByte(c.green);
        bo.writeByte(c.blue);
      }
    }

    return bo.getBytes();
  }

  public static function fromPaletteEntries(entries:Array<PaletteEntry>) {
    final chunk = new OldPaleteChunk(true);
    chunk.numPackets = 1;
    chunk.packets = [
      {
        skipEntries: 0,
        // Save at most 256 colors
        numColors: Std.int(Math.min(entries.length, 256)),
        colors: entries.slice(0, 256).map(e -> ({
          red: e.red,
          green: e.green,
          blue: e.blue
        }))
      }
    ];
    return chunk;
  }

  override function toString():String {
    return super.toString()
      +
      ' { numPackets: ${numPackets}, packets: [${packets.map(p -> '{ skipEntries: ${p.skipEntries}, numColors: ${p.numColors} }').join(', ')}] }';
  }

  private function new(?createHeader:Bool = false) {
    super(createHeader, OLD_PALETTE_04);
  }
}

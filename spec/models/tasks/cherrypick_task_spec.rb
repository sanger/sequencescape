require 'rails_helper'

RSpec.describe CherrypickTask, type: :model do
  context '#control_positions' do
    it 'calculates the positions for the control wells using the batch id and the plate number' do
      expect(CherrypickTask.new.control_positions(0, 0, 5, 2)).to eq([0,1])
      expect(CherrypickTask.new.control_positions(0, 1, 5,2)).to eq([1,2])
      expect(CherrypickTask.new.control_positions(0, 2, 5,2)).to eq([2,3])
      expect(CherrypickTask.new.control_positions(0, 3, 5,2)).to eq([3,4])
      expect(CherrypickTask.new.control_positions(0, 4, 5, 2)).to eq([4,0])

      expect(CherrypickTask.new.control_positions(0, 0, 2, 2)).to eq([0,1])
      expect{
        CherrypickTask.new.control_positions(0, 0, 2, 3)
      }.to raise_error(ZeroDivisionError)

      expect(CherrypickTask.new.control_positions(12345, 0, 100, 3)).to eq([23,22,1])
      expect(CherrypickTask.new.control_positions(12345, 1, 100, 3)).to eq([24,23,2])
      expect(CherrypickTask.new.control_positions(12345, 2, 100, 3)).to eq([25,24,3])

      expect(CherrypickTask.new.control_positions(12345+100, 0, 100, 3)).to eq([22,24,1])
      expect(CherrypickTask.new.control_positions(12345+100, 1, 100, 3)).to eq([23,25,2])
      expect(CherrypickTask.new.control_positions(12345+100, 2, 100, 3)).to eq([24,26,3])

      expect(CherrypickTask.new.control_positions(12345+200, 0, 100, 3)).to eq([21,25,1])
      expect(CherrypickTask.new.control_positions(12345+200, 1, 100, 3)).to eq([22,26,2])
      expect(CherrypickTask.new.control_positions(12345+200, 2, 100, 3)).to eq([23,27,3])

      expect(CherrypickTask.new.control_positions(12345, 0, 3, 1)).to eq([1])
      expect(CherrypickTask.new.control_positions(12345, 1, 3, 1)).to eq([2])
      expect(CherrypickTask.new.control_positions(12345, 2, 3, 1)).to eq([0])
      expect(CherrypickTask.new.control_positions(12345, 3, 3, 1)).to eq([1])
      expect(CherrypickTask.new.control_positions(12345, 4, 3, 1)).to eq([2])
    end
  end

end